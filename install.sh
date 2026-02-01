#!/bin/bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OpenClaw Custom WebChat Installer    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running from cloned repo
if [ -f "serve.js" ] && [ -f "index.html" ]; then
    echo -e "${GREEN}✓${NC} Running from cloned repository"
    INSTALL_DIR=$(pwd)
else
    echo -e "${YELLOW}⚠${NC}  Not in webchat directory"
    echo "This script should be run from the cloned repository."
    echo ""
    echo "First, clone the repository:"
    echo "  git clone git@github.com:davidcjones79/openclaw-custom-webchat.git"
    echo "  cd openclaw-custom-webchat"
    echo "  ./install.sh"
    exit 1
fi

echo ""
echo "Installation directory: ${INSTALL_DIR}"
echo ""

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js ${NODE_VERSION} found"
else
    echo -e "${RED}✗${NC} Node.js not found"
    echo "Please install Node.js: https://nodejs.org/"
    exit 1
fi

# Check OpenClaw
if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo -e "${GREEN}✓${NC} OpenClaw ${OPENCLAW_VERSION} found"
else
    echo -e "${YELLOW}⚠${NC}  OpenClaw not found (optional, but recommended)"
fi

# Check Tailscale
if command -v tailscale &> /dev/null; then
    echo -e "${GREEN}✓${NC} Tailscale found"
    HAS_TAILSCALE=true
else
    echo -e "${YELLOW}⚠${NC}  Tailscale not found (optional)"
    HAS_TAILSCALE=false
fi

echo ""
echo -e "${BLUE}Installation Options${NC}"
echo ""

# Ask about PM2
read -p "Install with PM2 for auto-restart? (recommended) [Y/n]: " USE_PM2
USE_PM2=${USE_PM2:-Y}

# Ask about Tailscale
if [ "$HAS_TAILSCALE" = true ]; then
    read -p "Setup Tailscale serving on port 8889? [Y/n]: " SETUP_TAILSCALE
    SETUP_TAILSCALE=${SETUP_TAILSCALE:-Y}
else
    SETUP_TAILSCALE="n"
fi

echo ""
echo -e "${BLUE}Starting installation...${NC}"
echo ""

# Get OpenClaw token if available
OPENCLAW_TOKEN=""
if [ -f ~/.openclaw/openclaw.json ]; then
    OPENCLAW_TOKEN=$(grep -A 4 '"auth"' ~/.openclaw/openclaw.json | grep '"token"' | cut -d'"' -f4 || echo "")
    if [ -n "$OPENCLAW_TOKEN" ]; then
        echo -e "${GREEN}✓${NC} Found OpenClaw token in config"
    fi
fi

# Install with PM2
if [[ $USE_PM2 =~ ^[Yy]$ ]]; then
    if ! command -v pm2 &> /dev/null; then
        echo -e "${YELLOW}Installing PM2...${NC}"
        npm install -g pm2
        echo -e "${GREEN}✓${NC} PM2 installed"
    else
        echo -e "${GREEN}✓${NC} PM2 already installed"
    fi

    # Stop existing instance if running
    pm2 stop openclaw-webchat 2>/dev/null || true
    pm2 delete openclaw-webchat 2>/dev/null || true

    # Start with PM2
    echo -e "${YELLOW}Starting webchat with PM2...${NC}"
    pm2 start serve.js --name openclaw-webchat
    pm2 save

    echo -e "${GREEN}✓${NC} Webchat started with PM2"
    echo ""
    echo "PM2 commands:"
    echo "  pm2 status           - Check status"
    echo "  pm2 logs webchat     - View logs"
    echo "  pm2 restart webchat  - Restart"
    echo "  pm2 stop webchat     - Stop"

    # Setup startup script
    read -p "Setup PM2 to auto-start on boot? [Y/n]: " SETUP_STARTUP
    SETUP_STARTUP=${SETUP_STARTUP:-Y}
    if [[ $SETUP_STARTUP =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Setting up PM2 startup...${NC}"
        pm2 startup
        echo ""
        echo -e "${YELLOW}⚠${NC}  Follow the command above to complete startup setup"
    fi
else
    # Start with node directly
    echo -e "${YELLOW}Starting webchat...${NC}"

    # Check if already running
    if lsof -i :8889 &> /dev/null; then
        echo -e "${YELLOW}⚠${NC}  Port 8889 already in use. Stopping existing process..."
        PID=$(lsof -ti :8889)
        kill $PID 2>/dev/null || true
        sleep 1
    fi

    nohup node serve.js > /tmp/openclaw-webchat.log 2>&1 &
    echo $! > /tmp/openclaw-webchat.pid

    echo -e "${GREEN}✓${NC} Webchat started (PID: $!)"
    echo "  Logs: /tmp/openclaw-webchat.log"
    echo "  To stop: kill \$(cat /tmp/openclaw-webchat.pid)"
fi

# Setup Tailscale
if [[ $SETUP_TAILSCALE =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Setting up Tailscale...${NC}"

    # Remove existing config
    tailscale serve --https=8889 off 2>/dev/null || true

    # Setup new config
    tailscale serve --bg --https 8889 http://127.0.0.1:8889

    echo -e "${GREEN}✓${NC} Tailscale serving configured"

    # Get Tailscale hostname
    TS_HOSTNAME=$(tailscale status --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | cut -d'"' -f4 | sed 's/\.$//' || echo "")
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation Complete! 🎉          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Display access URLs
echo -e "${BLUE}Access URLs:${NC}"
echo ""

# Local URL
GATEWAY_URL="ws://localhost:18789"
if [ -n "$OPENCLAW_TOKEN" ]; then
    echo -e "${GREEN}Local:${NC}"
    echo "  http://localhost:8889/?gateway=${GATEWAY_URL}&token=${OPENCLAW_TOKEN}"
else
    echo -e "${GREEN}Local:${NC}"
    echo "  http://localhost:8889/?gateway=${GATEWAY_URL}&token=YOUR_TOKEN"
    echo ""
    echo -e "${YELLOW}⚠${NC}  Get your token: cat ~/.openclaw/openclaw.json | grep '\"token\"'"
fi

echo ""

# Tailscale URL
if [[ $SETUP_TAILSCALE =~ ^[Yy]$ ]] && [ -n "$TS_HOSTNAME" ]; then
    GATEWAY_WSS="wss://${TS_HOSTNAME}"
    if [ -n "$OPENCLAW_TOKEN" ]; then
        echo -e "${GREEN}Tailscale (Remote):${NC}"
        echo "  https://${TS_HOSTNAME}:8889/?gateway=${GATEWAY_WSS}&token=${OPENCLAW_TOKEN}"
    else
        echo -e "${GREEN}Tailscale (Remote):${NC}"
        echo "  https://${TS_HOSTNAME}:8889/?gateway=${GATEWAY_WSS}&token=YOUR_TOKEN"
    fi
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Copy one of the URLs above"
echo "  2. Open it in your browser"
echo "  3. Start chatting with OpenClaw!"
echo ""

# Check if OpenClaw gateway is running
if ! lsof -i :18789 &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  OpenClaw gateway doesn't appear to be running on port 18789"
    echo "  Start it with: openclaw gateway"
    echo ""
fi

exit 0
