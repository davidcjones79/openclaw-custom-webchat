module.exports = {
  apps: [{
    name: 'webchat',
    script: '/opt/homebrew/bin/caddy',
    args: 'run --config /Users/davidjones/clawd/webchat/Caddyfile',
    cwd: '/Users/davidjones/clawd/webchat',
    watch: false,
    autorestart: true,
    max_restarts: 10,
    restart_delay: 1000,
    env: {
      XDG_DATA_HOME: '/opt/homebrew/var/lib'
    }
  }]
};
