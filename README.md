# OpenClaw Custom WebChat

Enhanced web interface for OpenClaw chat sessions with custom UI.

## Features

- Custom chat interface
- Direct WebSocket connection to OpenClaw gateway
- Static file serving on port 8889
- Tailscale integration support

## Requirements

- Node.js 18+
- OpenClaw instance running
- Optional: PM2 for process management
- Optional: Caddy for reverse proxy

## Installation

### Quick Start

```bash
# Clone anywhere you want - doesn't have to be ~/clawd
cd /path/to/your/preferred/location
git clone <YOUR_REPO_URL> webchat
cd webchat

# Start the server
node serve.js
```

**Note:** `~/clawd` is just the conventional OpenClaw workspace directory, but this webchat works from any location.

The webchat will be available at `http://localhost:8889`

### With PM2 (Recommended)

```bash
# Install PM2 globally if not already installed
npm install -g pm2

# Start with PM2
pm2 start serve.js --name openclaw-webchat

# Save PM2 configuration
pm2 save

# Setup auto-start on boot
pm2 startup
```

### With PM2 + Caddy

```bash
# Start with the ecosystem config (uses Caddy)
pm2 start ecosystem.config.js
pm2 save
```

## Usage

### Local Access

```
http://localhost:8889/?gateway=ws://localhost:18789&token=YOUR_TOKEN
```

### Tailscale Access

```
https://your-machine.your-tailnet.ts.net:8889/?gateway=wss://your-machine.your-tailnet.ts.net&token=YOUR_TOKEN
```

**To expose via Tailscale:**

```bash
tailscale serve --bg --https 8889 http://127.0.0.1:8889
```

## Configuration

Edit `serve.js` to change:
- `PORT`: Default is 8889
- `ROOT`: Web root directory

## File Structure

```
webchat/
├── serve.js              # Simple HTTP server
├── index.html           # Main chat interface
├── assets/              # CSS, JS, images
├── favicon*.png         # Favicon files
├── apple-touch-icon.png # iOS icon
├── ecosystem.config.js  # PM2 config (Caddy)
├── Caddyfile           # Caddy reverse proxy config
└── README.md           # This file
```

## Deployment to New Mac Mini

1. **Clone the repository (anywhere you want):**
   ```bash
   # Option 1: In OpenClaw workspace (recommended)
   cd ~/clawd
   git clone <YOUR_REPO_URL> webchat

   # Option 2: Any other location works too
   cd ~/apps  # or anywhere else
   git clone <YOUR_REPO_URL> webchat

   cd webchat
   ```

2. **Get your OpenClaw token:**
   ```bash
   # Read from OpenClaw config
   cat ~/.openclaw/openclaw.json | grep -A 2 '"auth"' | grep token
   ```

3. **Start the service:**
   ```bash
   # Option A: Simple node
   node serve.js &

   # Option B: With PM2
   pm2 start serve.js --name openclaw-webchat
   pm2 save
   pm2 startup
   ```

4. **Setup Tailscale serving (optional):**
   ```bash
   tailscale serve --bg --https 8889 http://127.0.0.1:8889
   ```

5. **Access the webchat:**
   - Local: `http://localhost:8889/?gateway=ws://localhost:18789&token=YOUR_TOKEN`
   - Remote: `https://YOUR-MACHINE.ts.net:8889/?gateway=wss://YOUR-MACHINE.ts.net&token=YOUR_TOKEN`

## Troubleshooting

### Port already in use
```bash
# Find process using port 8889
lsof -i :8889

# Kill the process
kill -9 <PID>
```

### WebSocket connection fails
- Check OpenClaw gateway is running: `openclaw status`
- Verify token is correct in URL
- Check firewall settings

### Tailscale not working
- Verify Tailscale serve status: `tailscale serve status`
- Check you're on the same tailnet
- Ensure HTTPS is being served on the correct port

## Development

To modify the interface, edit `index.html` and assets. The server will serve them immediately (no build step required).

## License

MIT

## Version

1.0.0
