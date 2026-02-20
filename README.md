# OpenClaw Docker Image (NAS Edition)

A Docker image for OpenClaw with pre-installed Chromium browser support, optimized for NAS deployments with automated updates.

## Features

- ✅ **Latest OpenClaw**: Automatically tracks and builds from the latest OpenClaw release
- ✅ **Chromium Browser**: Pre-installed Chromium browser for OpenClaw's browser tool
- ✅ **Auto Updates**: GitHub Actions workflow checks for new OpenClaw releases every 6 hours
- ✅ **Multi-architecture**: Supports both AMD64 and ARM64 (perfect for Raspberry Pi NAS)
- ✅ **Persistent Storage**: Preserves configuration, workspace, and browser cache across restarts

## Quick Start

### Using Docker Run

```bash
docker run -d \
  --name openclaw-nas \
  --restart unless-stopped \
  -p 18789:18789 \
  -e OPENCLAW_GATEWAY_BIND=lan \
  -v openclaw-data:/home/node/.openclaw \
  -v openclaw-workspace:/home/node/workspace \
  -v openclaw-browser-cache:/home/node/.cache/ms-playwright \
  ghcr.io/waterlou/openclaw:latest
```

### Using Docker Compose (Recommended)

```bash
# Clone this repo
git clone https://github.com/waterlou/openclaw.git
cd openclaw

# Create .env file with your API keys
cat > .env << EOF
ANTHROPIC_API_KEY=your-key-here
# Or use your preferred provider:
# OPENAI_API_KEY=your-key-here
# GEMINI_API_KEY=your-key-here
EOF

# Start the container
docker compose up -d

# View logs
docker compose logs -f

# Stop the container
docker compose down
```

### ARM64 / Raspberry Pi NAS

**Option 1: Build locally (faster for first-time setup)**

If you're on an ARM64 system (Raspberry Pi, Synology, etc.) and the pre-built image isn't available yet:

```bash
# Clone this repo
git clone https://github.com/waterlou/openclaw.git
cd openclaw

# Create .env file
cat > .env << EOF
ANTHROPIC_API_KEY=your-key-here
EOF

# Build locally for ARM64
docker build -t waterlou/openclaw:arm64-latest .

# Start with local build
sed -i 's|image: ghcr.io/waterlou/openclaw:latest|image: waterlou/openclaw:arm64-latest|' docker-compose.yml

# Start the container
docker compose up -d
```

**Option 2: Wait for GitHub Actions (pull pre-built image)**

The GitHub Actions workflow builds ARM64 images automatically. After the workflow completes (~10-15 minutes):

```bash
# Pull the ARM64 image
docker compose pull

# Start the container
docker compose up -d
```

To check the workflow status:
- Go to: https://github.com/waterlou/openclaw/actions
- Wait for the "Auto-build on OpenClaw Release" workflow to complete ✅

## Environment Variables

### AI Providers (at least one required)

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key (Claude models) |
| `OPENAI_API_KEY` | OpenAI API key (GPT models) |
| `GEMINI_API_KEY` | Google Gemini API key |
| `OPENROUTER_API_KEY` | OpenRouter API key |
| `MISTRAL_API_KEY` | Mistral API key |
| And more... | See [OpenClaw docs](https://docs.openclaw.ai) |

### Gateway Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_GATEWAY_BIND` | `lan` | Network bind mode (`lan`, `loopback`, `auto`) |
| `OPENCLAW_GATEWAY_TOKEN` | auto-generated | Bearer token for gateway auth |
| `OPENCLAW_GATEWAY_PORT` | `18789` | Gateway port number |

### Browser Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PLAYWRIGHT_BROWSERS_PATH` | `/home/node/.cache/ms-playwright` | Chromium cache location |

## Accessing OpenClaw

Once the container is running, you can access OpenClaw in several ways:

### 1. Web UI

Open your browser to: `http://your-nas-ip:18789`

### 2. CLI from another container

```bash
# Use the same image for CLI operations
docker compose exec openclaw openclaw --help
docker compose exec openclaw openclaw agents list
docker compose exec openclaw openclaw gateway status
```

### 3. Connect from your app

Configure your OpenClaw client or app to connect to:
- Host: `your-nas-ip`
- Port: `18789`
- Token: (use `docker compose exec openclaw openclaw --token` to retrieve)

## Using the Browser Tool

This image includes Chromium browser pre-installed via Playwright. To use it:

```bash
# Test browser tool
docker compose exec openclaw openclaw browser status

# Open a URL
docker compose exec openclaw openclaw browser open https://example.com
```

The browser cache is persisted in the `openclaw-browser-cache` volume.

## Automated Updates

This repository uses GitHub Actions to automatically rebuild when new OpenClaw releases are available:

- **Schedule**: Every 6 hours (00:00, 06:00, 12:00, 18:00 UTC)
- **Trigger**: Manual trigger via GitHub Actions UI with options:
  - Force rebuild even if version exists
  - Skip `:latest` tag update
- **Checks**: Compares image tags before building to avoid unnecessary builds

### Manual Trigger

1. Go to Actions tab in this repository
2. Select "Auto-build on OpenClaw Release"
3. Click "Run workflow"
4. Configure options if needed
5. Click "Run workflow"

To update your running container after a new build:

```bash
docker compose pull
docker compose up -d
```

## Available Tags

- `latest` - Tracks the most recent OpenClaw release
- `X.Y.Z` - Specific OpenClaw version (e.g., `1.2.3`)
- `X.Y` - Major.Minor version (e.g., `1.2`)
- `X` - Major version (e.g., `1`)

## Building Locally

```bash
# Build the image
docker build -t openclaw-nas:local .

# Run with custom config
docker run -d \
  --name openclaw-custom \
  -p 18789:18789 \
  -v $(pwd)/config:/home/node/.openclaw \
  openclaw-nas:local
```

## Troubleshooting

### Browser not working

Check browser cache volume:
```bash
docker volume inspect openclaw-browser-cache
```

Recreate if needed:
```bash
docker compose down -v
docker compose up -d
```

### Permission errors

Ensure your config/workspace volumes are accessible:
```bash
docker compose exec openclaw ls -la /home/node/.openclaw
```

### View logs

```bash
# All logs
docker compose logs

# Follow logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail 100
```

### Gateway not starting

Check health status:
```bash
docker compose ps
docker compose exec openclaw node dist/index.js health
```

## Advanced: Browser Sidecar (Optional)

For a full desktop browser UI with noVNC, uncomment the `browser` service in `docker-compose.yml`.

This provides:
- **Desktop UI**: Access browser at `http://your-nas-ip:6901`
- **CDP Access**: Remote debugging via port 9222
- **Better anti-detection**: Headless browser reduces bot blocking

Then set `BROWSER_CDP_URL=http://browser:9222` in the openclaw service environment.

## Resource Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 1 core | 2+ cores |
| RAM | 512MB | 1-2GB |
| Disk | 1GB | 5GB+ |
| Network | - | Stable internet for API calls |

## Architecture

```
┌─────────────────────────────────────────────┐
│  Docker Container (openclaw-nas)            │
│                                              │
│  OpenClaw Gateway (port 18789)               │
│  ↓                                           │
│  Chromium Browser (via Playwright)           │
│  ↓                                           │
│  Browser Cache (persisted volume)            │
│                                              │
└─────────────────────────────────────────────┘

  Volumes:
  ├── openclaw-data (config, state)
  ├── openclaw-workspace (user projects)
  └── openclaw-browser-cache (Chromium data)
```

## Support

- **OpenClaw Documentation**: https://docs.openclaw.ai
- **OpenClaw GitHub**: https://github.com/openclaw/openclaw
- **Issues**: Open an issue in this repository

## License

This Docker image follows the same license as OpenClaw.

---

Built with 🦞 by the OpenClaw community
