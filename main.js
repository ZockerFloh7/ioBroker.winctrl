'use strict';

const utils = require('@iobroker/adapter-core');
const REQUEST_TIMEOUT_MS = 600000;
const HEARTBEAT_MS = 30000;

class Winctrl extends utils.Adapter {
    constructor(options) {
        super({ ...options, name: 'winctrl' });
        this.stopping = false;
        this.busy = false;
        this.pinging = false;
        this.controllers = new Set();
        this.heartbeat = null;
        this.on('ready', this.onReady.bind(this));
        this.on('stateChange', this.onStateChange.bind(this));
        this.on('unload', this.onUnload.bind(this));
    }

    async onReady() {
        const states = {
            command: {
                name: 'Command / trigger',
                type: 'string',
                role: 'text',
                read: true,
                write: true,
                def: '',
                desc: 'netflix or /netflix, also paths such as media/pause',
            },
            status: {
                name: 'Execution status',
                type: 'number',
                role: 'value',
                read: true,
                write: false,
                min: 0,
                max: 2,
                def: 0,
                states: { 0: 'failed', 1: 'running', 2: 'success' },
            },
            response: {
                name: 'Response / return value',
                type: 'string',
                role: 'text',
                read: true,
                write: false,
                def: '',
            },
            httpStatus: {
                name: 'HTTP status code (0 = no response)',
                type: 'number',
                role: 'value',
                read: true,
                write: false,
                def: 0,
            },
            lastError: {
                name: 'Last execution error',
                type: 'string',
                role: 'text',
                read: true,
                write: false,
                def: '',
            },
            lastCommand: {
                name: 'Last trigger sent',
                type: 'string',
                role: 'text',
                read: true,
                write: false,
                def: '',
            },
            'info.connection': {
                name: 'Device connection to Windows PC',
                type: 'boolean',
                role: 'indicator.connected',
                read: true,
                write: false,
                def: false,
            },
        };
        await this.setObjectNotExistsAsync('info', { type: 'channel', common: { name: 'Information' }, native: {} });
        // Update existing metadata as well: older status objects stored HTTP codes.
        for (const [id, common] of Object.entries(states)) {
            await this.extendObjectAsync(id, { type: 'state', common, native: {} });
        }
        await this.setStateAsync('info.connection', { val: false, ack: true });
        const previous = await this.getStateAsync('status');
        if (previous && previous.val === 1) {
            await this.writeResult(
                0,
                'Adapter restarted; result of the previous run is unknown.',
                0,
                'The previous run was not observed to completion.',
            );
        }
        try {
            this.baseUrl = makeBaseUrl(this.config.clientIp, this.config.port);
            if (!String(this.config.token || '').trim()) {
                throw new Error('Token is missing in the instance settings.');
            }
        } catch (error) {
            this.log.error(error.message);
            await this.setStateAsync('lastError', { val: error.message, ack: true });
            return;
        }
        await this.subscribeStatesAsync('command');
        await this.checkConnection();
        this.heartbeat = this.setInterval(() => {
            void this.checkConnection().catch(error => this.log.debug(`Heartbeat: ${error.message}`));
        }, HEARTBEAT_MS);
    }

    async request(path, timeoutMs) {
        const controller = new AbortController();
        this.controllers.add(controller);
        const timer = this.setTimeout(() => controller.abort(), timeoutMs);
        try {
            const url = new URL(this.baseUrl);
            url.pathname = path;
            const res = await fetch(url, {
                method: 'GET',
                redirect: 'error',
                signal: controller.signal,
                headers: { Authorization: `Bearer ${this.config.token}`, Accept: 'application/json' },
            });
            // Timer deliberately remains active while reading the body.
            const text = await res.text();
            let data = null;
            try {
                data = JSON.parse(text);
            } catch {
                /* handled by caller */
            }
            return { code: res.status, data, text };
        } catch (error) {
            if (controller.signal.aborted) {
                throw new Error(
                    this.stopping
                        ? 'Adapter is stopping.'
                        : `Request timed out after ${timeoutMs / 1000} seconds; the Windows action may still be running.`,
                );
            }
            // Do not log URL/config/headers or nested errors containing credentials.
            throw new Error(`WinCtrl request failed (${error.code || error.name || 'network error'}).`);
        } finally {
            this.clearTimeout(timer);
            this.controllers.delete(controller);
        }
    }

    async checkConnection() {
        if (this.stopping || this.pinging || this.busy || !this.baseUrl) {
            return;
        }
        this.pinging = true;
        try {
            const res = await this.request('/ping', 4000);
            if (!this.stopping && !this.busy) {
                await this.setStateAsync('info.connection', { val: isWinCtrlPing(res), ack: true });
            }
        } catch {
            if (!this.stopping && !this.busy) {
                await this.setStateAsync('info.connection', { val: false, ack: true });
            }
        } finally {
            this.pinging = false;
        }
    }

    async writeResult(status, response, httpCode, error) {
        await Promise.all([
            this.setStateAsync('status', { val: status, ack: true }),
            this.setStateAsync('response', { val: response, ack: true }),
            this.setStateAsync('httpStatus', { val: httpCode, ack: true }),
            this.setStateAsync('lastError', { val: error || '', ack: true }),
        ]);
    }

    async onStateChange(id, state) {
        if (this.stopping || !state || state.ack || id !== `${this.namespace}.command`) {
            return;
        }
        if (this.busy) {
            this.log.warn('Command not executed: the previous request is still running.');
            return;
        }
        this.busy = true;
        try {
            const trigger = normalizeTrigger(state.val);
            await Promise.all([
                this.setStateAsync('status', { val: 1, ack: true }),
                this.setStateAsync('response', { val: '', ack: true }),
                this.setStateAsync('lastError', { val: '', ack: true }),
                this.setStateAsync('httpStatus', { val: 0, ack: true }),
                this.setStateAsync('lastCommand', { val: trigger, ack: true }),
            ]);
            const res = await this.request(trigger, REQUEST_TIMEOUT_MS);
            if (this.stopping) {
                return;
            }
            const data = res.data;
            if (res.code === 401 || res.code === 403) {
                await this.setStateAsync('info.connection', { val: false, ack: true });
                await this.writeResult(0, 'Token was rejected.', res.code, 'Authentication failed.');
            } else if (data && [0, 1, 2].includes(data.status)) {
                await this.setStateAsync('info.connection', { val: true, ack: true });
                const result = interpretResponse(res);
                await this.writeResult(result.status, result.response, res.code, result.error);
            } else {
                await this.writeResult(
                    0,
                    'Invalid WinCtrl response (JSON expected).',
                    res.code,
                    'No valid status response received. Check the Windows app and token.',
                );
                await this.setStateAsync('info.connection', { val: false, ack: true });
            }
        } catch (error) {
            if (this.stopping) {
                return;
            }
            await this.writeResult(0, error.message, 0, error.message);
            await this.setStateAsync('info.connection', { val: false, ack: true });
            this.log.warn(error.message);
        } finally {
            // Confirm only if no newer command was written in the meantime.
            if (!this.stopping) {
                try {
                    const latest = await this.getStateAsync('command');
                    if (latest && !latest.ack && latest.ts === state.ts && latest.val === state.val) {
                        await this.setStateAsync('command', { val: state.val, ack: true });
                    }
                } catch (error) {
                    this.log.debug(`Acknowledgement: ${error.message}`);
                }
            }
            this.busy = false;
        }
    }

    onUnload(callback) {
        this.stopping = true;
        if (this.heartbeat) {
            this.clearInterval(this.heartbeat);
        }
        for (const controller of this.controllers) {
            controller.abort();
        }
        this.setState('info.connection', { val: false, ack: true }, () => callback());
    }
}

function makeBaseUrl(hostValue, portValue) {
    const host = String(hostValue || '').trim();
    const port = Number(portValue || 8085);
    if (!host || /[\s/?#@]/.test(host) || host.includes('://')) {
        throw new Error('Enter only a hostname or IP address, without http:// and without a path.');
    }
    if (!Number.isInteger(port) || port < 1 || port > 65535) {
        throw new Error('Port must be between 1 and 65535.');
    }
    const formatted = host.includes(':') && !host.startsWith('[') ? `[${host}]` : host;
    return new URL(`http://${formatted}:${port}/`).toString();
}

function normalizeTrigger(value) {
    const path = `/${String(value ?? '')
        .trim()
        .replace(/^\/+/, '')}`;
    if (!/^\/[A-Za-z0-9_/-]+$/.test(path)) {
        throw new Error('Invalid trigger; use e.g. netflix or /media/pause.');
    }
    if (path === '/ping') {
        throw new Error('/ping is reserved for the connection check and is not a script trigger.');
    }
    return path;
}

function isWinCtrlPing(res) {
    const d = res.data;
    if (!d || res.code === 401 || res.code === 403) {
        return false;
    }
    if (res.code === 200 && (d.response === 'pong' || d.status_text === 'pong' || d.service === 'winctrl')) {
        return true;
    }
    // Compatibility with the last Windows package lacking a built-in /ping route.
    // Not ANY 404: only the exact WinCtrl JSON error with the configured token.
    return (
        res.code === 404 &&
        d.status === 0 &&
        d.status_text === 'failed' &&
        d.error === 'Not Found' &&
        d.response === 'Unbekannte oder deaktivierte Aktion'
    );
}

function interpretResponse(res) {
    const d = res.data;
    const success = res.code >= 200 && res.code < 300 && d.status === 2;
    const response = String(d.return_value ?? d.response ?? '');
    if (success) {
        return { status: 2, response, error: '' };
    }
    const error =
        res.code === 409 || d.status === 1
            ? 'Windows is already running another action; this request was not started.'
            : String(d.error || d.response || `HTTP ${res.code}`);
    return { status: 0, response: error, error };
}

if (require.main !== module) {
    module.exports = options => new Winctrl(options);
    module.exports.helpers = { makeBaseUrl, normalizeTrigger, isWinCtrlPing, interpretResponse };
} else {
    new Winctrl();
}
