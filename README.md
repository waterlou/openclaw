# OpenClaw Docker Image

A Docker image for OpenClaw with pre-installed Playwright Chromium browser and additional CLI tools.

## Features

- OpenClaw gateway
- Playwright Chromium browser
- Multi-architecture support (linux/amd64, linux/arm64)

## Extra Tools

- **[bw](https://github.com/bitwarden/cli)** - Official Bitwarden CLI for secure password management
- **[codex](https://openai.com/index/codex-now-generally-available/)** - OpenAI Codex CLI for coding tasks from the terminal
- **[himalaya](https://github.com/pimalaya/himalaya)** - CLI email client for managing emails
- **[gh](https://cli.github.com/)** - GitHub CLI for interacting with GitHub from the command line
- **[gws](https://github.com/googleworkspace/cli)** - Google Workspace CLI
- **[notesmd-cli](https://github.com/Yakitrak/notesmd-cli)** - Interact with Obsidian vaults from the terminal
- **poppler-utils** - PDF command-line tools (for example `pdftotext`, `pdfinfo`)
- **postgresql-client** - PostgreSQL client tools (for example `psql`)

## Python Packages

- `python3` and `pip` are installed in the image
- `ib_insync` is preinstalled for Interactive Brokers API workflows

## Package Versions (Build 2026-03-14)

- `bw` 2026.2.0
- `codex` 0.114.0
- `gws` 0.16.0
- `gh` 2.88.1
- `himalaya` 1.2.0
- `ib_insync` 0.9.86

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

## License

Same as OpenClaw.
