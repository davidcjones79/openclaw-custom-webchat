const path = require('path');

module.exports = {
  apps: [{
    name: 'webchat',
    script: '/opt/homebrew/bin/caddy',
    args: `run --config ${path.join(__dirname, 'Caddyfile')}`,
    cwd: __dirname,
    watch: false,
    autorestart: true,
    max_restarts: 10,
    restart_delay: 1000,
    env: {
      XDG_DATA_HOME: '/opt/homebrew/var/lib'
    }
  }]
};
