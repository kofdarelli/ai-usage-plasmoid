# Security policy

If you discover a security vulnerability in AI Usage, please report it privately instead of opening a public issue.

## How to report

Open a private [GitHub Security Advisory](https://github.com/kofdarelli/ai-usage-plasmoid/security/advisories/new) or contact the maintainer directly.

## Scope

Security issues include but are not limited to:

- Credential leakage or exposure through the widget, helper, or cache file.
- Code execution or file access beyond the widget's intended scope.
- Unsafe handling of untrusted API responses.

The widget reads local credential files and makes outbound API requests to `api.anthropic.com` and the local Codex app-server. Any issue affecting credential safety or network security is in scope.

## Response

The maintainer will acknowledge reports within 72 hours and work toward a fix before public disclosure.
