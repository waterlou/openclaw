# AGENTS.md

This file documents the tools and configurations added to the OpenClaw Docker image.

## Extra CLI Tools

### Bitwarden CLI (bw)
- **Repository:** https://github.com/bitwarden/cli
- **Description:** Official Bitwarden CLI for secure password management
- **Installation:** Built from source using Node.js 20 LTS
- **Support:** linux/amd64, linux/arm64

### Unofficial Bitwarden CLI (rbw)
- **Repository:** https://github.com/doy/rbw
- **Description:** Unofficial Bitwarden CLI with background agent
- **Installation:** Built from source using Rust
- **Support:** linux/amd64, linux/arm64

### Himalaya
- **Repository:** https://github.com/pimalaya/himalaya
- **Description:** CLI email client for managing emails
- **Installation:** Downloaded from GitHub releases
- **Support:** linux/amd64

### GitHub CLI (gh)
- **Repository:** https://cli.github.com/
- **Description:** GitHub CLI for interacting with GitHub from the command line
- **Installation:** Installed via apt repository
- **Support:** linux/amd64, linux/arm64

### Google Suite CLI (gogcli)
- **Repository:** https://github.com/steipete/gogcli
- **Description:** Google Suite CLI: Gmail, Calendar, Drive, Contacts, Sheets, Forms, and more
- **Installation:** Built from source using Go
- **Support:** linux/amd64, linux/arm64

## Docker Build Configuration

### Multi-Stage Builds
The Dockerfile uses multi-stage builds to support multiple architectures:

1. **bw-builder** - Bitwarden CLI builder (Node.js 20)
2. **rbw-builder** - Unofficial Bitwarden CLI builder (Rust 1.81)
3. **gog-builder** - Google Suite CLI builder (Go 1.26)

### Supported Architectures
- linux/amd64
- linux/arm64

### Base Image
- `ghcr.io/openclaw/openclaw:latest`

### Additional Features
- Playwright Chromium browser
- CI mode enabled (skips TTY prompts)
- Global pnpm store at `/app/.pnpm-store`

## Environment Variables

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `OPENAI_API_KEY` | OpenAI API key |
| `GEMINI_API_KEY` | Google Gemini API key |
| `OPENCLAW_GATEWAY_BIND` | Network bind mode (default: `lan`) |
| `PLAYWRIGHT_BROWSERS_PATH` | Playwright browsers cache path |

## Quick Start

```bash
# Clone this repo
git clone https://github.com/waterlou/openclaw.git
cd openclaw

# Create .env file with your API key
echo "ANTHROPIC_API_KEY=your-key-here" > .env

# Build and start
docker compose up -d

# View logs
docker compose logs -f
```

## Access

- **OpenClaw Gateway:** http://localhost:18789
