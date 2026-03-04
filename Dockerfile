# OpenClaw with Playwright Chromium
# Supports: linux/amd64, linux/arm64

FROM ghcr.io/openclaw/openclaw:latest

# Enables CI mode: skips TTY prompts
ENV CI=true  

# Install Playwright system dependencies and Chromium
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Playwright/Chromium dependencies
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
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Set Playwright browsers path
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright

WORKDIR /app

# Global store at /app/.pnpm-store + relink deps before Playwright
RUN mkdir -p .pnpm-store && \
    pnpm config set store-dir /app/.pnpm-store --global && \
    pnpm install --frozen-lockfile --ignore-scripts && \
    pnpm add -w vite --ignore-scripts && \
    pnpm add -w playwright-core --ignore-scripts && \
    pnpm exec playwright-core install --with-deps chromium

# Create browser cache directory
RUN mkdir -p /home/node/.cache/ms-playwright && \
    chown -R node:node /home/node/.cache /app/.pnpm-store /app/node_modules
#RUN mkdir -p /home/node/.cache/ms-playwright && \
#    chown -R node:node /home/node/.cache/ms-playwright

# Install himalaya CLI email tool
RUN curl -sSL https://raw.githubusercontent.com/pimalaya/himalaya/master/install.sh | PREFIX=/usr/local sh

# Switch back to node user
USER node

# Expose OpenClaw gateway port
EXPOSE 18789

# Start OpenClaw gateway
CMD ["node", "dist/index.js", "gateway"]
