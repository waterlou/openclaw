# Multi-stage build for OpenClaw with Chromium browser support
# Base: Latest OpenClaw official image
# Adds: Chromium browser for OpenClaw's browser tool

FROM ghcr.io/openclaw/openclaw:latest AS base

# Install Chromium and browser dependencies
# These are required for Chromium to run in a headless/container environment
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright Chromium browser for OpenClaw's browser tool
# Use the playwright-core CLI to install only Chromium (smaller footprint)
RUN node /app/node_modules/playwright-core/cli.js install chromium

# Set Playwright browsers path to persistent cache location
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright

# Ensure cache directory exists and is owned by node user
RUN mkdir -p /home/node/.cache/ms-playwright && \
    chown -R node:node /home/node/.cache/ms-playwright

# Switch back to node user for security
USER node

# Expose standard OpenClaw gateway port
EXPOSE 18789

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node dist/index.js health --token "${OPENCLAW_GATEWAY_TOKEN:-}" || exit 1

# Keep the original OpenClaw entrypoint
CMD ["node", "dist/index.js", "gateway"]
