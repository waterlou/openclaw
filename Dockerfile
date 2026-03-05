# OpenClaw with Playwright Chromium
# Supports: linux/amd64, linux/arm64

# gogcli builder - Google Suite CLI
FROM golang:1.26-bookworm AS gog-builder
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/steipete/gogcli.git /build/gogcli && \
    cd /build/gogcli && \
    make && \
    mkdir -p /output/bin && \
    cp /build/gogcli/bin/gog /output/bin/gog && \
    strip /output/bin/gog

# notesmd-cli builder
FROM golang:1.26-bookworm AS notesmd-builder
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/Yakitrak/notesmd-cli.git /build/notesmd-cli && \
    cd /build/notesmd-cli && \
    mkdir -p /output/bin && \
    go build -o /output/bin/notesmd-cli . && \
    strip /output/bin/notesmd-cli

FROM ghcr.io/openclaw/openclaw:latest

# Install Playwright system dependencies and Chromium
USER root

COPY --from=gog-builder /output/bin/gog /usr/local/bin/gog
RUN chmod +x /usr/local/bin/gog && gog --version

COPY --from=notesmd-builder /output/bin/notesmd-cli /usr/local/bin/notesmd-cli
RUN chmod +x /usr/local/bin/notesmd-cli && notesmd-cli --help >/dev/null

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

USER node

# Download Chromium for Playwright using existing dependencies from base image
RUN mkdir -p /home/node/.cache/ms-playwright && \
    pnpm exec playwright-core install chromium

USER root

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

# Install Bitwarden CLI (bw) to /usr/local/bin for amd64 + arm64
RUN npm config set registry https://registry.npmjs.org/ && \
    npm view @bitwarden/cli version && \
    npm install --global @bitwarden/cli --registry=https://registry.npmjs.org/ && \
    command -v bw && \
    bw --version

# Switch back to node user
USER node

# Expose OpenClaw gateway port
EXPOSE 18789

# Start OpenClaw gateway
CMD ["node", "dist/index.js", "gateway"]
