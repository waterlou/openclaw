#!/bin/bash
# OpenClaw Browser Entrypoint with Remote Access Support
# Starts: Xvfb, Fluxbox, x11vnc, noVNC, Chromium (with CDP), and OpenClaw gateway

set -e

# Configuration from environment
DISPLAY=${DISPLAY:-:99}
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}
SCREEN_DEPTH=${SCREEN_DEPTH:-24}
VNC_PORT=${VNC_PORT:-5900}
NOVNC_PORT=${NOVNC_PORT:-6901}
CDP_PORT=${CDP_PORT:-9222}
VNC_PASSWORD=${VNC_PASSWORD:-openclaw}

echo "=============================================="
echo "  OpenClaw Browser with Remote Access"
echo "=============================================="
echo "  Gateway:     http://localhost:18789"
echo "  Web Browser: http://localhost:${NOVNC_PORT}"
echo "  VNC:         vnc://localhost:${VNC_PORT}"
echo "  CDP:         http://localhost:${CDP_PORT}"
echo "  VNC Password: ${VNC_PASSWORD}"
echo "=============================================="

# Cleanup function
cleanup() {
    echo "Shutting down services..."
    kill $XVFB_PID $FLUXBOX_PID $X11VNC_PID $NOVNC_PID $CHROMIUM_PID 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# Start Xvfb (Virtual Framebuffer)
echo "[1/5] Starting Xvfb virtual display..."
Xvfb ${DISPLAY} \
    -screen 0 ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH} \
    -ac +extension GLX +extension RENDER -noreset &
XVFB_PID=$!
sleep 2

# Start Fluxbox window manager
echo "[2/5] Starting Fluxbox window manager..."
fluxbox -display ${DISPLAY} -log /tmp/fluxbox.log &
FLUXBOX_PID=$!
sleep 1

# Start x11vnc for VNC access (listen on all interfaces)
echo "[3/5] Starting x11vnc on port ${VNC_PORT}..."
x11vnc -display ${DISPLAY} \
    -forever \
    -shared \
    -rfbport ${VNC_PORT} \
    -passwd ${VNC_PASSWORD} \
    -bg \
    -o /tmp/x11vnc.log \
    -noxdamage \
    -cursor_arrow \
    -nopw \
    -listen 0.0.0.0
sleep 2

# Start noVNC for web-based access
# Listen on 0.0.0.0 to accept connections from any IP
echo "[4/5] Starting noVNC websockify on port ${NOVNC_PORT}..."
cd /opt/novnc
websockify --web=/opt/novnc 0.0.0.0:${NOVNC_PORT} 127.0.0.1:${VNC_PORT} &
NOVNC_PID=$!
sleep 2

# Start Chromium with CDP enabled (headful mode for VNC visibility)
echo "[5/5] Starting Chromium with CDP on port ${CDP_PORT}..."
chromium-browser \
    --display=${DISPLAY} \
    --remote-debugging-port=${CDP_PORT} \
    --remote-debugging-address=0.0.0.0 \
    --no-first-run \
    --no-default-browser-check \
    --disable-background-networking \
    --disable-extensions \
    --disable-sync \
    --disable-translate \
    --disable-default-apps \
    --disable-popup-blocking \
    --disable-notifications \
    --start-maximized \
    --disable-gpu \
    --disable-software-rasterizer \
    --disable-dev-shm-usage \
    --no-sandbox \
    about:blank &
CHROMIUM_PID=$!
sleep 2

echo ""
echo "=============================================="
echo "  All services started successfully!"
echo "=============================================="
echo ""
echo "  Access the browser:"
echo "    Web:     http://<your-ip>:${NOVNC_PORT}/vnc.html"
echo "    VNC:     vnc://<your-ip>:${VNC_PORT} (password: ${VNC_PASSWORD})"
echo "    CDP:     http://<your-ip>:${CDP_PORT}"
echo ""
echo "  OpenClaw Gateway: http://<your-ip>:18789"
echo "=============================================="
echo ""

# Keep script running and show logs
echo "Services running. Press Ctrl+C to stop."
echo ""

# Start OpenClaw gateway in foreground
cd /app
exec node dist/index.js gateway
