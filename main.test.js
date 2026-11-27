'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const mainPath = path.join(__dirname, 'main.js');
const adapterModule = { exports: {} };
function mockRequire(name) {
    if (name === '@iobroker/adapter-core') {
        return { Adapter: class {
            constructor() {
                throw new Error('Unit-Tests dürfen keine Adapterinstanz starten.');
            }
        } };
    }
    throw new Error(`Nicht erwarteter Import im Helper-Test: ${name}`);
}
vm.runInNewContext(fs.readFileSync(mainPath, 'utf8'), {
    require: mockRequire,
    module: adapterModule,
    exports: adapterModule.exports,
    URL,
}, { filename: mainPath, timeout: 5000 });

const h = adapterModule.exports.helpers;
assert.ok(h, 'main.js muss seine helpers exportieren.');

function result(code, data) {
    // Normalize cross-context prototypes before structural comparison.
    return JSON.parse(JSON.stringify(h.interpretResponse({ code, data })));
}

test('IPv4 und Port ergeben korrekte Basis-URL', () => {
    assert.equal(h.makeBaseUrl('192.168.2.78', 8085), 'http://192.168.2.78:8085/');
});
test('Hostname und Standardport werden unterstützt', () => {
    assert.equal(h.makeBaseUrl('windows-pc', undefined), 'http://windows-pc:8085/');
});
test('IPv6-Adresse wird geklammert', () => {
    assert.equal(h.makeBaseUrl('::1', 8085), 'http://[::1]:8085/');
});
test('Leerer Host sowie URL/Pfad statt Host werden abgewiesen', () => {
    for (const host of ['', 'http://windows-pc', 'windows-pc/test', 'user@host', 'bad host']) {
        assert.throws(() => h.makeBaseUrl(host, 8085));
    }
});
test('Ungültige Ports werden abgewiesen', () => {
    for (const port of [-1, 65536, 1.5, 'abc']) {
        assert.throws(() => h.makeBaseUrl('windows-pc', port));
    }
});
test('Trigger ohne Slash wird normalisiert', () => {
    assert.equal(h.normalizeTrigger('netflix'), '/netflix');
});
test('Verschachtelter Trigger bleibt erhalten', () => {
    assert.equal(h.normalizeTrigger('/media/pause'), '/media/pause');
});
test('Whitespace und führende Slashes werden normalisiert', () => {
    assert.equal(h.normalizeTrigger('  //netflix  '), '/netflix');
});
test('Leere, fremde URL- und Query-Trigger werden abgewiesen', () => {
    for (const trigger of ['', null, '/', 'http://evil.invalid', 'test?token=secret', 'test#fragment']) {
        assert.throws(() => h.normalizeTrigger(trigger));
    }
});
test('/ping ist für die Verbindungsprüfung reserviert', () => {
    assert.throws(() => h.normalizeTrigger('/ping'), /reserved/);
});
test('Nativer Pong bestätigt die Verbindung', () => {
    assert.equal(h.isWinCtrlPing({ code: 200, data: { response: 'pong' } }), true);
});
test('Service-Kennung bestätigt die Verbindung', () => {
    assert.equal(h.isWinCtrlPing({ code: 200, data: { service: 'winctrl' } }), true);
});
test('401 und 403 bestätigen auch mit Pong keine Verbindung', () => {
    for (const code of [401, 403]) {
        assert.equal(h.isWinCtrlPing({ code, data: { response: 'pong' } }), false);
    }
});
test('Beliebige 404-Antwort wird nicht als Ping-Erfolg gewertet', () => {
    assert.equal(h.isWinCtrlPing({ code: 404, data: { error: 'Not Found' } }), false);
});
test('Bekannte alte WinCtrl-404-Antwort wird kompatibel erkannt', () => {
    assert.equal(h.isWinCtrlPing({ code: 404, data: {
        status: 0, status_text: 'failed', error: 'Not Found',
        response: 'Unbekannte oder deaktivierte Aktion',
    } }), true);
});
test('Fehlendes JSON bestätigt keine Verbindung', () => {
    assert.equal(h.isWinCtrlPing({ code: 200, data: null }), false);
});
test('Erfolgreiche Aktion liefert Rückgabewert', () => {
    assert.deepEqual(result(200, { status: 2, return_value: 'Grüße äöü' }), {
        status: 2, response: 'Grüße äöü', error: '',
    });
});
test('Expliziter leerer Rückgabewert bleibt leer', () => {
    assert.equal(result(200, { status: 2, return_value: '', response: 'OK' }).response, '');
});
test('response dient als Fallback ohne return_value', () => {
    assert.equal(result(200, { status: 2, response: 'OK' }).response, 'OK');
});
test('HTTP 409 bedeutet: neuer Auftrag nicht gestartet', () => {
    const r = result(409, { status: 1, response: 'busy' });
    assert.equal(r.status, 0);
    assert.match(r.error, /not started/);
});
test('Windows-Fehlertext wird übernommen', () => {
    const r = result(500, { status: 0, error: 'Fenster nicht gefunden nach 10 Sekunden' });
    assert.equal(r.status, 0);
    assert.equal(r.error, 'Fenster nicht gefunden nach 10 Sekunden');
});
test('HTTP-Fehler wird nicht durch JSON-status=2 zum Erfolg', () => {
    assert.equal(result(500, { status: 2, response: 'Fehler' }).status, 0);
});
