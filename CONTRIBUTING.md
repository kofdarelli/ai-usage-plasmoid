# Contributing

Contributions are welcome. Please open an issue first for discussion before submitting a pull request.

## Development setup

1. Clone the repository.
2. Ensure Node.js 18+ and KDE Plasma 6 are available.
3. Run `./build.sh` to produce a `.plasmoid` package in `dist/`.
4. Install with `kpackagetool6 --type Plasma/Applet --upgrade dist/ai-usage-*.plasmoid` and restart Plasma.

## Guidelines

- Keep changes focused: one feature or fix per pull request.
- Test against both Claude Code and Codex before submitting.
- Do not commit credentials, tokens, or cached usage data.
- Do not hardcode upstream API field names -- use the defensive `normalizeWindow()` pattern in `ai-usage-status` so the widget survives minor API changes.
- Match the existing code style (ESLint-free Node.js, QML 6 conventions, 4-space indentation).
