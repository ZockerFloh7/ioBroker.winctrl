# ioBroker.winctrl

Control a Windows PC from ioBroker through the separate WinCtrl Windows companion application.

This adapter sends configured action triggers to the companion's HTTP command server.
The Windows companion executes the action and returns its result to ioBroker.
Actions may contain Windows-side Blockly plans, for example to start an application,
control a window, send keyboard input or operate a media player.

## Project status

Version 0.0.3 is a public test release.

## Requirements

- Node.js 22.19.0 or newer, as declared by this adapter's package.json.
- An ioBroker installation compatible with the adapter's dependencies.
- Download the Windows companion application: [WinCtrl Companion v0.0.3](https://github.com/ZockerFloh7/winctrl-companion/releases/download/v0.0.3/WinCtrl-0.0.3-windows-x64.exe).
- Network access from the ioBroker host to the Windows command-server port.
- A configured command-server token.

The adapter may run on a different machine from the Windows PC, including an ioBroker
container. Configure the Windows PC's reachable IP address or hostname; do not use
127.0.0.1 unless the command server is actually reachable through the adapter host's
loopback interface.

## Prepare the Windows companion

1. Install and start the compatible WinCtrl Windows application.
2. Configure its command-server address, port and a new authentication token.
3. Create an action and assign a trigger such as /netflix.
4. Enable the action. Disabled actions cannot be invoked by their HTTP trigger.
5. If the companion's IP whitelist is enabled, allow the source IP seen for your
   ioBroker host. Token authentication remains necessary.
6. Test the Windows action locally before triggering it from ioBroker.

Desktop automation requires the appropriate interactive Windows session. Actions may
not work as expected on a locked desktop, secure prompts or applications with different
privilege levels. Validate each action on the intended Windows PC.

## Install the adapter

For a locally built development package:

1. Run npm pack in the adapter source directory.
2. Install the resulting .tgz file through the ioBroker Admin custom-source file installer.
3. Open the adapter instance settings and configure the connection.

Do not install the Windows application's update ZIP as an ioBroker adapter package.

## Instance settings

| Setting | Meaning |
| --- | --- |
| clientIp | Windows IP address or hostname, without http://, port or path |
| port | Command-server TCP port; default 8085 |
| token | The exact token configured in the Windows companion |

The adapter uses HTTP GET and sends the token as an Authorization: Bearer header.
Do not put the token into command values or trigger names.

## Data points

Replace winctrl.0 with your actual instance ID if necessary.

| Data point | Type | Writable | Meaning |
| --- | --- | --- | --- |
| command | string | yes | Action trigger to execute, e.g. netflix or /media/pause |
| status | number | no | 0 = failed, 1 = request running, 2 = success |
| response | string | no | Action return value on success, otherwise a diagnostic message |
| httpStatus | number | no | HTTP response code; 0 if no response code was recorded |
| lastError | string | no | Last execution error; cleared when a new execution starts |
| lastCommand | string | no | Last normalized trigger prepared for sending |
| info.connection | boolean | no | Last observed reachability/authentication result |

httpStatus = 0 can also occur before a request is sent, for example when trigger validation
fails. It is not exclusively a network-timeout indicator.

## Execute an action

Write a trigger to winctrl.0.command with ack=false.

Example using the ioBroker JavaScript adapter:

```javascript
setState('winctrl.0.command', 'netflix', false);
```

The adapter normalizes the trigger to /netflix. It sets status to 1 while waiting
for the HTTP response, then sets status to 2 on success or 0 on failure.
Read response for the action's returned string. An explicitly returned empty string
remains empty and is not replaced with OK.

Use the Windows companion's return-value block to provide a result from its Blockly plan.
Writing a command is an execution request; the acknowledged command value is not proof
that the action succeeded. Inspect status, response and lastError.

## Execution behavior and limits

- Execution requests have a fixed 600-second timeout, including reading the response body.
- This limit also applies to otherwise healthy long-running Windows actions.
- A timeout or adapter shutdown does not guarantee that a Windows action has stopped.
- Failed requests are not retried automatically, to avoid duplicate execution.
- Only one execution request is handled at a time per adapter instance. Additional
  commands received while busy are rejected with a log warning, not queued.
- Do not use a rejected additional command to infer a result from the active request's
  data points: those data points still describe the active request.
- A Windows busy response (HTTP 409) fails the new request because it was not started.
- status = 1 means that this adapter is waiting for a response. It is not independent
  confirmation of the Windows worker's current state.
- After restarting during an observed running request, the adapter reports that the
  previous result is unknown. It does not resume observing that Windows job.
- /ping is reserved for connection checks and cannot be submitted as a command.

## Connection monitoring

A connection check runs during startup and is scheduled every 30 seconds. Its own timeout
is 4 seconds. New checks are skipped while an execution request or another ping is active.

The companion should provide an authenticated /ping endpoint. The adapter recognizes its
Pong response. It also supports one specific legacy WinCtrl JSON 404 response for older
companions without a native ping endpoint; arbitrary HTTP 404 responses are not accepted.

info.connection is the latest observation, not a persistent connection or a guarantee
that the next action will succeed. An execution failure can still leave it true when
an authenticated WinCtrl response was received.

## Security

- HTTP is unencrypted: the token and command traffic are not protected in transit.
- Use a trusted LAN or VPN; do not expose the command server through an Internet port forward.
- Use the companion's IP whitelist and appropriate Windows firewall rules.
- The token field is masked and listed in protectedNative. This does not mean that
  the stored token has been encrypted by this adapter.
- Protect ioBroker backups and configuration files containing credentials.
- Rotate any token accidentally shared in a log, screenshot, repository or support request.
- Actions can start applications, send input and close windows. Review plans before enabling
  them. Closing windows may affect unsaved work.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Token missing in instance settings | Enter and save the companion token in the adapter settings. |
| HTTP 401 or 403 | Check both the token and the Windows companion's IP whitelist. The current adapter uses a generic authentication message for these response codes. |
| Unknown or disabled action | Check the trigger spelling and whether the Windows action is enabled. |
| HTTP 409 | Another Windows action is running; the new action was not started. |
| Request timeout | Check connectivity and action duration. The Windows action may still be running; do not blindly retry. |
| Invalid JSON response | Check the host, port and compatible companion protocol; ensure the request is reaching WinCtrl. |
| Window not found | Check the title and Windows session, or wait for the window before operating on it. |

## Development and checks

```text
npm ci
npm run check:syntax
npm run lint
npm test
npm run test:integration
```

npm test runs helper unit tests and package-file validation. The integration test currently
uses JS-Controller 7.2.5 and checks basic adapter startup. With an empty default token,
startup logs a configuration error and skips HTTP initialization; this smoke test does
not validate successful command execution.

See the repository's issue tracker for bug reports. Never include tokens in reports.

## Changelog

### 0.0.4

- (ZockerFloh7) Updated dependencies, metadata and CI configuration for ioBroker repository submission.
- (ZockerFloh7) Configured npm trusted publishing.

### 0.0.3 — public test release

- Token-authenticated HTTP action requests.
- Execution status and returned values.
- Connection monitoring and separate HTTP/error diagnostic data points.
- Fixed execution-request timeout and basic automated checks.

Older entries can be found in [CHANGELOG_OLD.md](CHANGELOG_OLD.md).

## License

MIT License

Copyright (c) 2026 ZockerFloh7 <zockerfloh7@posteo.de>

See [LICENSE](LICENSE) for the full license text.