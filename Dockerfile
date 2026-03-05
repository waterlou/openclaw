# OpenClaw with Playwright Chromium
# Supports: linux/amd64, linux/arm64

# rbw to /usr/local/bin - amd64 + arm64 (correct tags)
FROM rust:1.81-slim-bookworm AS rbw-builder
WORKDIR /build
# PIN STABLE VERSION - no edition2024
RUN cargo install rbw --version 1.13.2 --locked && \
    mkdir -p /output/bin && \
    cp $(which rbw) /output/bin/rbw && \
    strip /output/bin/rbw

# gogcli builder - Google Suite CLI
FROM golang:1.22-slim-bookworm AS gog-builder
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/steipete/gogcli.git /build/gogcli && \
    cd /build/gogcli && \
    make && \
    mkdir -p /output/bin && \
    cp /build/gogcli/bin/gog /output/bin/gog && \
    strip /output/bin/gog

FROM ghcr.io/openclaw/openclaw:latest

# Enables CI mode: skips TTY prompts
ENV CI=true  

# Install Playwright system dependencies and Chromium
USER root

COPY --from=rbw-builder /output/bin/rbw /usr/local/bin/rbw
RUN chmod +x /usr/local/bin/rbw && \
    apt-get update --allow-releaseinfo-change -y && \
    apt-get install -y --no-install-recommends pinentry-tty && \
    rm -rf /var/lib/apt/lists/* && \
    rbw --version

COPY --from=gog-builder /output/bin/gog /usr/local/bin/gog
RUN chmod +x /usr/local/bin/gog && \
    gog --version

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

# Install github cli tool
RUN (type -p wget >/dev/null || (apt update && apt install wget -y)) \
	&& mkdir -p -m 755 /etc/apt/keyrings \
	&& out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& mkdir -p -m 755 /etc/apt/sources.list.d \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt update \
	&& apt install gh -y

# Switch back to node user
USER node

# Expose OpenClaw gateway port
EXPOSE 18789

# Start OpenClaw gateway
CMD ["node", "dist/index.js", "gateway"]
