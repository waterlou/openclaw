# OpenClaw Docker Image

A Docker image for OpenClaw with pre-installed Playwright Chromium browser and additional CLI tools.

## Features

- OpenClaw gateway
- Playwright Chromium browser
- Multi-architecture support (linux/amd64, linux/arm64)
- Preinstalled `lossless-claw` context engine plugin

## Extra Tools

- **[bw](https://github.com/bitwarden/cli)** - Official Bitwarden CLI for secure password management
- **[camoufox](https://github.com/daijro/camoufox)** - Stealth-focused Firefox-based browser with Python wrapper and CLI
- **[codex](https://openai.com/index/codex-now-generally-available/)** - OpenAI Codex CLI for coding tasks from the terminal
- **[instagram-cli](https://github.com/supreme-gg-gg/instagram-cli)** - Instagram CLI (TypeScript client)
- **[himalaya](https://github.com/pimalaya/himalaya)** - CLI email client for managing emails
- **[gh](https://cli.github.com/)** - GitHub CLI for interacting with GitHub from the command line
- **[gws](https://github.com/googleworkspace/cli)** - Google Workspace CLI
- **[notesmd-cli](https://github.com/Yakitrak/notesmd-cli)** - Interact with Obsidian vaults from the terminal
- **poppler-utils** - PDF command-line tools (for example `pdftotext`, `pdfinfo`)
- **postgresql-client** - PostgreSQL client tools (for example `psql`)
- **tmux** - Terminal multiplexer

## Python Packages

- `python3` and `pip` are installed in the image
- `ib_insync` is preinstalled for Interactive Brokers API workflows
- `camoufox` is preinstalled, and its browser binaries are fetched during image build

## Included Plugins

- **[lossless-claw](https://github.com/Martian-Engineering/lossless-claw)** - Lossless Context Management plugin for OpenClaw, bundled into the image

## Package Versions (Build 2026-03-31)

- `bw` 2026.2.0
- `camoufox` Python package 0.4.11
- `camoufox` browser 135.0.1-beta.24
- `codex` 0.117.0
- `instagram-cli` 1.4.5
- `lossless-claw` 0.5.2
- `gws` 0.22.5
- `gh` 2.89.0
- `himalaya` 1.2.0
- `ib_insync` 0.9.86

Note: installing `instagram-cli` currently emits deprecation warnings for some dependencies during build. This is expected from upstream and does not block the install.

`gws` is installed from the upstream musl release artifact so it remains compatible with the Debian 12 / glibc 2.36 runtime used by this image.

## `gws` Headless Auth

Reference: [googleworkspace/cli README - Service Account (server-to-server)](https://github.com/googleworkspace/cli?tab=readme-ov-file#service-account-server-to-server)

### Service account (server-to-server)

No browser login is required. Mount your service account key and point `gws` to it:

```bash
docker run --rm -it \
  -v /path/to/service-account.json:/run/secrets/gws-sa.json:ro \
  -e GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE=/run/secrets/gws-sa.json \
  openclaw gws drive files list
```

### Optional: pre-obtained access token

If your environment already mints OAuth tokens (for example with `gcloud`), you can use:

```bash
docker run --rm -it \
  -e GOOGLE_WORKSPACE_CLI_TOKEN="$(gcloud auth print-access-token)" \
  openclaw gws drive files list
```

`gws` auth precedence (highest first): `GOOGLE_WORKSPACE_CLI_TOKEN`, then `GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE`.

## Quick Start

```bash
# Clone this repo
git clone https://github.com/waterlou/openclaw.git
cd openclaw

# Create .env file with your API key(s)
echo "ANTHROPIC_API_KEY=your-key-here" > .env
echo "OPENAI_API_KEY=your-key-here" >> .env

# Build and start
docker compose up -d

# View logs
docker compose logs -f
```

## Access

- **OpenClaw Gateway:** http://localhost:18789

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `OPENCLAW_GATEWAY_BIND` | Network bind mode (default: `lan`) |

## Build

```bash
docker build -t openclaw .
```

## Codex CLI

`codex` is installed globally in the image at `/usr/local/bin/codex`.

To use it inside the running container:

```bash
docker compose exec openclaw codex --help
```

For interactive use in the OpenClaw workspace:

```bash
docker compose exec -it openclaw sh
cd /home/node/workspace
codex
```

`OPENAI_API_KEY` must be set for Codex CLI commands.

## Camoufox

`camoufox` is installed globally in the image, and the browser files are pre-fetched into `/home/node/.cache/camoufox`.

To verify the install inside the running container:

```bash
docker compose exec openclaw python3 -m camoufox version
docker compose exec openclaw /home/node/.cache/camoufox/camoufox-bin --version
```

Example Python usage:

```bash
docker compose exec openclaw python3 - <<'PY'
from camoufox.sync_api import Camoufox

with Camoufox(headless=True) as browser:
    page = browser.new_page()
    page.goto("https://example.com")
    print(browser.version)
PY
```

## Lossless Claw

`lossless-claw` is bundled into `/app/extensions/lossless-claw`, which is OpenClaw's stock plugin directory. This keeps the plugin available even when Docker Compose mounts `/home/node/.openclaw` as a volume.

On container start, the entrypoint seeds `/home/node/.openclaw/openclaw.json` with `lossless-claw` enabled if that plugin entry is missing. Existing plugin settings in the mounted volume are left unchanged.

To verify it inside the running container:

```bash
docker compose exec openclaw test -d /app/extensions/lossless-claw && echo installed
docker compose exec openclaw sh -lc "openclaw plugins list | grep lossless"
```

The plugin stores its SQLite database at `/home/node/.openclaw/lcm.db` by default, so its data still lives in the mounted OpenClaw state volume. It uses OpenClaw's configured model/provider unless you set `lossless-claw` plugin config or `LCM_*` environment overrides.

## License

Same as OpenClaw.
