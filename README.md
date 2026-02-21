# OpenClaw Docker Image

A Docker image for OpenClaw with pre-installed Playwright Chromium browser.

## Features

- OpenClaw gateway
- Playwright Chromium browser
- Multi-architecture support (linux/amd64, linux/arm64)

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

## License

Same as OpenClaw.
