<div align="center">
  <img src="views/logo.png" alt="Blorq" height="72"/>
  <h1>blorq-cli</h1>
  <p><strong>Production-grade, open-source log aggregator.</strong><br/>One command to install. Runs as a system service on macOS, Linux & Windows.</p>

  <a href="https://www.npmjs.com/package/blorq"><img src="https://img.shields.io/npm/v/blorq?color=blue&label=npm" alt="npm version"/></a>
  <a href="https://www.npmjs.com/package/blorq"><img src="https://img.shields.io/npm/dm/blorq?color=blue" alt="npm downloads"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license"/></a>
  <img src="https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey" alt="Platforms"/>
</div>

---

## Table of Contents

- [Installation](#installation)
  - [macOS / Linux (recommended)](#macos--linux-recommended)
  - [Windows (PowerShell)](#windows-powershell)
  - [npm (global)](#npm-global)
  - [npx (no install)](#npx-no-install)
  - [Docker](#docker)
- [Quick Start](#quick-start)
- [CLI Reference](#cli-reference)
- [Auto-start on Boot](#auto-start-on-boot)
- [Add to Your Node.js App](#add-to-your-nodejs-app)
- [Configuration](#configuration)
- [Features](#features)
- [File Layout](#file-layout)
- [Security Checklist](#security-checklist)
- [License](#license)

---

## Installation

### macOS / Linux (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/blroq/blorq-cli/main/install.sh | bash
```

Start immediately:

```bash
blorq start
# → Dashboard: http://localhost:9900   (admin / admin123)
```

### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/blroq/blorq-cli/main/install.ps1 | iex
```

### npm (global)

```bash
npm install -g blorq
blorq setup   # creates data/, .env, and default users
blorq start
```

### npx (no install)

```bash
npx blorq start   # downloads and runs immediately — no global install required
```

### Docker

```bash
docker run -d \
  -p 9900:9900 \
  -v $PWD/data:/data \
  -v $PWD/logs:/logs \
  -e JWT_SECRET=your-32-char-secret \
  --name blorq \
  --restart unless-stopped \
  ghcr.io/your-org/blorq:latest
```

Or with Docker Compose:

```bash
docker compose up -d
```

---

## Quick Start

After installation, open the dashboard:

| | |
|---|---|
| **URL** | `http://localhost:9900` |
| **Username** | `admin` |
| **Password** | `admin123` |

1. Open the dashboard — you'll see an empty state.
2. Navigate to **API Keys** → create a key with the `logs:write` scope.
3. Send your first log:

```bash
curl -X POST http://localhost:9900/api/logs \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: blq_your_key" \
  -d '{
    "appName": "test",
    "logs": ["{\"level\":\"info\",\"message\":\"Hello Blorq!\",\"ts\":\"2024-01-15T10:00:00Z\"}"]
  }'
```

4. Refresh the dashboard — your service appears in the list.

---

## CLI Reference

```
USAGE
  blorq <command> [options]

PROCESS MANAGEMENT
  blorq start                     Start server in foreground
  blorq start --background        Start server as a background daemon
  blorq start --port <port>       Start on a custom port (default: 9900)
  blorq stop                      Stop the background instance
  blorq restart                   Restart the background instance
  blorq status                    Show running status and PID

SETUP
  blorq setup                     First-run: create data/, .env, and default users
  blorq open                      Open the dashboard in your default browser

OS SERVICE (auto-start on boot)
  blorq service install           Register as an OS service
  blorq service uninstall         Remove the OS service
  blorq service start             Start the OS service
  blorq service stop              Stop the OS service
  blorq service restart           Restart the OS service
  blorq service logs              Tail OS service logs

INFO
  blorq --version                 Print version number
  blorq --help                    Print this help message
```

---

## Auto-start on Boot

Register Blorq as a persistent OS service so it survives reboots:

```bash
blorq service install
```

| Platform | Method | Location |
|---|---|---|
| **macOS** | launchd | `~/Library/LaunchAgents/` |
| **Linux** | systemd user unit | `~/.config/systemd/user/blorq.service` |
| **Windows** | Windows Service via `sc.exe` | Run as Administrator |

---

## Add to Your Node.js App

Install the companion logger package:

```bash
npm install blorq-logger
```

```js
const logger = require('blorq-logger');

logger.configure({
  appName:   'my-api',
  remoteUrl: 'http://localhost:9900/api/logs',
  apiKey:    process.env.BLORQ_API_KEY,
});

// Express: one-line request metrics middleware
app.use(logger.requestLogger());

// Structured logging
logger.info('Server started', { port: 3000 });
logger.error('DB timeout', new Error('Connection refused'));

// Drop-in console patch — all console.* calls ship to Blorq automatically
logger.install();
```

See the [blorq-logger](https://www.npmjs.com/package/blorq-logger) package for full docs covering Next.js, Fastify, Koa, NestJS, and plain Node adapters.

---

## Configuration

All configuration is via environment variables or a `.env` file (auto-loaded from the install directory):

```env
# .env

PORT=9900
DATA_DIR=./data           # users, keys, roles, settings
LOG_BASE_DIR=./logs       # ingested log files
JWT_SECRET=your-32-char-secret
RETENTION_DAYS=7
NODE_ENV=production
```

See [`.env.example`](.env.example) for the full list of available options.

---

## Features

| Feature | Details |
|---|---|
| **RBAC** | Built-in admin/viewer roles + unlimited custom roles |
| **API Key Management** | Multi-key, SHA-256 hashed, per-key scopes, expiry & revoke |
| **IP Whitelist** | Restrict ingest endpoint to specific IPs or `/24` ranges |
| **2FA (TOTP)** | Per-user optional TOTP — compatible with Google Authenticator |
| **Log Analytics** | Hourly charts, level breakdown, 7-day trend, top services |
| **API Analytics** | Per-endpoint latency, error rates, trend analysis |
| **Real-time Stream** | SSE live log feed for instant visibility |
| **Drag & Drop Dashboard** | Rearrange widgets; role-based card visibility |
| **User Management** | Create/delete users, reset passwords, revoke 2FA — all from the UI |
| **Role Config** | Visual per-role page and card-level permissions |

---

## File Layout

```
~/.blorq/                   # runtime files (macOS/Linux default)
  blorq.pid                 # PID of background process
  blorq.log                 # stdout from background process
  stdout.log                # service stdout (when using blorq service)
  stderr.log                # service stderr

[install dir]/
  bin/blorq                 # CLI binary
  data/                     # users.json, api-keys.json, settings.json, role-config.json
  logs/                     # ingested logs (one dir per service, one file per day)
  server.js                 # HTTP server entry point
  config/index.js           # all configuration
```

---

## Security Checklist

Before exposing Blorq in a production environment:

```
✅ Set JWT_SECRET to ≥ 32 random characters
✅ Set NODE_ENV=production
✅ Change the default admin and viewer passwords
✅ Create per-service API keys with the minimum required scopes
✅ Place Blorq behind a reverse proxy (nginx / Caddy) with TLS
✅ Mount data/ and logs/ as persistent volumes when using Docker
```

---

## License

[MIT](LICENSE) — free to use, modify, and distribute.
