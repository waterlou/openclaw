# OpenClaw + Chromium with Remote Access Support
# Includes: noVNC (web), VNC (direct), and CDP (programmatic)
# Supports: linux/amd64, linux/arm64

# Use coollabsio/openclaw which has multi-arch support
FROM coollabsio/openclaw:latest AS base

# Install Chromium, browser dependencies, and remote access tools
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Browser dependencies
    ca-certificates \
    fonts-liberation \
    fonts-noto-cjk \
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
    # Remote desktop dependencies
    x11vnc \
    xvfb \
    fluxbox \
    websockify \
    python3-numpy \
    # Utilities
    curl \
    jq \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright Chromium
RUN node /app/node_modules/playwright-core/cli.js install chromium

# Install noVNC for web-based remote access
RUN mkdir -p /opt/novnc && \
    curl -fsSL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar xzf - -C /opt/novnc --strip-components=1 && \
    curl -fsSL https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar xzf - -C /opt/novnc/utils --strip-components=1 && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Copy startup scripts
COPY scripts/entrypoint-browser.sh /opt/entrypoint-browser.sh
RUN chmod +x /opt/entrypoint-browser.sh

# Environment variables
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright \
    DISPLAY=:99 \
    VNC_PORT=5900 \
    NOVNC_PORT=6901 \
    CDP_PORT=9222 \
    VNC_PASSWORD=openclaw \
    SCREEN_WIDTH=1920 \
    SCREEN_HEIGHT=1080 \
    SCREEN_DEPTH=24

# Create browser cache directory
RUN mkdir -p /home/node/.cache/ms-playwright && \
    chown -R node:node /home/node/.cache/ms-playwright

# Expose ports
# 18789 - OpenClaw gateway
# 5900   - VNC direct access
# 6901   - noVNC web interface
# 9222   - Chrome DevTools Protocol (CDP)
EXPOSE 18789 5900 6901 9222

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:18789/health || exit 1

# Start with browser remote access
ENTRYPOINT ["/opt/entrypoint-browser.sh"]
