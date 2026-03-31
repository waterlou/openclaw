# OpenClaw with Playwright Chromium
# Supports: linux/amd64, linux/arm64

# notesmd-cli builder
FROM golang:1.26-bookworm AS notesmd-builder
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/Yakitrak/notesmd-cli.git /build/notesmd-cli && \
    cd /build/notesmd-cli && \
    mkdir -p /output/bin && \
    go build -o /output/bin/notesmd-cli . && \
    strip /output/bin/notesmd-cli

FROM ghcr.io/openclaw/openclaw:latest

ARG LOSSLESS_CLAW_VERSION=0.5.2

# Install Playwright system dependencies and Chromium
USER root

COPY --from=notesmd-builder /output/bin/notesmd-cli /usr/local/bin/notesmd-cli
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/notesmd-cli && notesmd-cli --help >/dev/null
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

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
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    fonts-liberation \
    poppler-utils \
    postgresql-client \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Set Playwright browsers path
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright
ENV LD_LIBRARY_PATH=/home/node/.cache/camoufox

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

# Install Google Workspace CLI (gws) to /usr/local/bin for amd64 + arm64
RUN npm config set registry https://registry.npmjs.org/ && \
    npm view @googleworkspace/cli version && \
    npm install --global @googleworkspace/cli --registry=https://registry.npmjs.org/ && \
    command -v gws && \
    gws --version

# Install Instagram CLI (TypeScript client) to /usr/local/bin for amd64 + arm64
RUN npm config set registry https://registry.npmjs.org/ && \
    npm view @i7m/instagram-cli version && \
    npm install --global @i7m/instagram-cli --registry=https://registry.npmjs.org/ && \
    command -v instagram-cli && \
    instagram-cli --help

# Install OpenAI Codex CLI to /usr/local/bin for amd64 + arm64
RUN npm config set registry https://registry.npmjs.org/ && \
    npm view @openai/codex version && \
    npm install --global @openai/codex --registry=https://registry.npmjs.org/ && \
    command -v codex && \
    codex --version

# Install Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages \
    ib_insync \
    camoufox && \
    python3 -c "import ib_insync; print(ib_insync.__version__)" && \
    command -v camoufox && \
    camoufox --help >/dev/null

RUN mkdir -p /home/node/.openclaw && \
    chown -R node:node /home/node/.openclaw

# Bundle lossless-claw into OpenClaw's stock extensions directory so it survives
# the /home/node/.openclaw volume mount from docker compose.
RUN tmpdir="$(mktemp -d)" && \
    cd "$tmpdir" && \
    tarball="$(npm pack @martian-engineering/lossless-claw@${LOSSLESS_CLAW_VERSION} | tail -n 1)" && \
    rm -rf /app/extensions/lossless-claw && \
    mkdir -p /app/extensions/lossless-claw && \
    tar -xzf "$tarball" -C /app/extensions/lossless-claw --strip-components=1 && \
    rm -rf "$tmpdir" && \
    chown -R node:node /app/extensions/lossless-claw && \
    test -f /app/extensions/lossless-claw/openclaw.plugin.json && \
    test -f /app/extensions/lossless-claw/index.ts

# Switch back to node user
USER node

RUN python3 -m camoufox fetch && \
    python3 -m camoufox path && \
    python3 -m camoufox version

# Expose OpenClaw gateway port
EXPOSE 18789

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Start OpenClaw gateway
CMD ["node", "dist/index.js", "gateway"]
