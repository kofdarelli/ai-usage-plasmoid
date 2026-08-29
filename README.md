# AI Usage for KDE Plasma 6

A desktop widget that shows your current Claude Code and Codex usage limits with live reset countdowns. Each service gets a card with a usage ring, remaining quota, and a countdown to the next window reset.

## Screenshot

The widget renders as a translucent Liquid Glass panel on your desktop. Each card shows:

- **Usage ring** -- percentage of the current window consumed
- **Window label** -- "5H" (5-hour), "7D" (7-day), or whatever the current window is
- **Countdown** -- time remaining until the window resets
- **Reset badges** (Codex only) -- available/used quota resets

Click any card to force an immediate refresh.

## Requirements

| Requirement | Details |
|---|---|
| **KDE Plasma 6** | Works on Wayland and X11 |
| **Node.js 18+** | The bundled helper uses the built-in `fetch` API |
| **Claude Code** | Must be signed in so `~/.claude/.credentials.json` exists |
| **Codex CLI** | Must be installed and signed in (`codex` on your PATH) |
| **Network** | Claude usage is fetched from `api.anthropic.com`; Codex usage comes from the local app-server |

No credentials are bundled with the widget. The helper reads them locally and only sends the Claude OAuth token to Anthropic's API.

## Installation

Download the `.plasmoid` file from the [releases page](https://github.com/kofdarc/ai-usage-plasmoid/releases) and install it:

```sh
kpackagetool6 --type Plasma/Applet --install ai-usage-1.0.0.plasmoid
```

If you already have an older version installed, use `--upgrade` instead of `--install`.

Then right-click your desktop, choose **Add Widgets**, and search for **AI Usage**. Drag it onto your desktop.

> **Placement tip:** This widget uses a Liquid Glass effect that captures the wallpaper behind it. For the best visual result, place it directly on the desktop (not in a panel). Panels do not have a wallpaper scene, so the glass falls back to a dark translucent squircle.

## Setup

### Claude Code

Sign in to Claude Code if you haven't already:

```sh
claude
```

The widget reads your OAuth token from `~/.claude/.credentials.json`. If you use a custom credentials path, set `AI_USAGE_CLAUDE_CREDENTIALS` to the full path.

### Codex CLI

Sign in to the Codex CLI:

```sh
codex auth login
```

The widget communicates with the Codex app-server over stdio to read rate limits. No network calls are made -- everything stays local.

### Optional: Second Codex profile (Codex M)

If you have a second Codex profile (e.g. for a different OpenAI account), the widget can show a third card. Place your secondary profile at `~/.codex-codexm/` (must contain `auth.json`). The third card appears automatically when the profile is detected.

## Configuration

The widget works out of the box with no configuration. If you need to override defaults, set these environment variables before starting Plasma (e.g. in `~/.config/environment.d/`):

| Variable | Default | Purpose |
|---|---|---|
| `AI_USAGE_CLAUDE_CREDENTIALS` | `~/.claude/.credentials.json` | Path to Claude OAuth credentials |
| `AI_USAGE_CODEX_BIN` | `codex` | Path to the Codex CLI binary |
| `AI_USAGE_CODEX_HOME` | `~/.codex` | Primary Codex profile directory |
| `AI_USAGE_CODEX_SECONDARY_HOME` | `~/.codex-codexm` | Secondary Codex profile directory |
| `AI_USAGE_CODEX_SECONDARY_CONFIG_HOME` | `~/.config-codexm` | Secondary Codex config directory |

## How it works

```
                      ai-usage-status (Node.js helper)
                      /                \
          Claude OAuth API       Codex app-server (stdio)
          (api.anthropic.com)     (local, no network)
                      \                /
                     JSON on stdout
                           |
                     Plasma DataSource
                     (refreshes every 5 min)
                           |
                     QML widget renders
```

1. Every 5 minutes (or on click), Plasma runs the `ai-usage-status` helper.
2. The helper reads Claude credentials and calls the Anthropic usage API.
3. The helper spawns `codex app-server --stdio` and reads rate limits over the local JSON protocol.
4. Results are written to stdout as JSON and cached to `~/.cache/ai-usage-status.json`.
5. The QML widget parses the JSON and updates the rings and countdowns.

If a service is unreachable or its API shape changes, the widget degrades gracefully:
- **Last-good cache** -- previously successful data is shown with a stale indicator
- **Fallback labels** -- window labels are derived from remaining time, not hardcoded
- **Dash display** -- if no data is available at all, rings show a dash instead of a misleading "0%"

## Troubleshooting

**Widget shows dashes for everything**
- Check that Claude Code is signed in: `cat ~/.claude/.credentials.json | head -5`
- Check that Codex is signed in: `codex auth status`
- Check Node.js version: `node --version` (must be 18+)

**Widget shows stale data**
- Click any card to force a refresh
- Check if the Codex app-server is responding: `echo '{"method":"initialize","id":1,"params":{"clientInfo":{"name":"test","version":"0.0.1"}}}' | codex app-server --stdio`
- Check the cache file: `cat ~/.cache/ai-usage-status.json | python3 -m json.tool`

**Glass effect not working**
- The widget must be placed on the desktop, not in a panel
- Panels have no wallpaper scene, so the glass falls back to a dark translucent squircle (this is expected behavior)

**Codex M card not appearing**
- The secondary profile must exist at `~/.codex-codexm/auth.json`
- If your paths differ, set `AI_USAGE_CODEX_SECONDARY_HOME` and `AI_USAGE_CODEX_SECONDARY_CONFIG_HOME`

## Privacy

- Credentials never leave your machine (Claude token is sent only to `api.anthropic.com`)
- Codex usage is read over a local stdio process -- no network calls
- Cache file is created with `0600` permissions (owner-only)
- No telemetry, analytics, or phone-home

## Building from source

```sh
./build.sh
```

The `.plasmoid` file (a zip archive) is written to `dist/`.

## Compatibility

The widget reads data from:
- **Anthropic's Claude Code OAuth usage endpoint** (`api.anthropic.com/api/oauth/usage`)
- **Codex CLI's app-server rate-limits interface** (local stdio protocol)

These interfaces may change in future versions of Claude Code or Codex CLI. The helper uses defensive field normalization (multiple known aliases per field) to tolerate minor API changes without breaking. If a major API change occurs, a helper update may be needed.

## Credits and license

The Liquid Glass QML component and shaders are derived from [macOS Widgets](https://github.com/jaxparrow07/macos-widgets) by Jack Faith. That project and this widget are licensed under the GNU General Public License v3.0 only. See `LICENSE`.

The included Claude and Codex product marks belong to their respective owners and are used only to identify the services. This project is not affiliated with Anthropic or OpenAI.
