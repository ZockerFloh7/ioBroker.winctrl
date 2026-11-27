# Development

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
