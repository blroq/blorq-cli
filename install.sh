#!/usr/bin/env bash
# Blorq — One-command installer for macOS & Linux
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/blroq/blorq-cli/main/install.sh | bash

set -e

# ── Colours ────────────────────────────────────────────
RESET='\033[0m'
GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
RED='\033[31m'

ok()   { echo -e "${GREEN}  ✓${RESET} $*"; }
info() { echo -e "${CYAN}  →${RESET} $*"; }
warn() { echo -e "${YELLOW}  ⚠${RESET} $*"; }
fail() { echo -e "${RED}  ✗${RESET} $*"; exit 1; }

# ── Config ─────────────────────────────────────────────
PORT="${PORT:-9900}"
DATA_DIR="${DATA_DIR:-$HOME/.blorq}"

# ── Banner ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}==================================${RESET}"
echo -e "${CYAN}     Blorq Log Aggregator        ${RESET}"
echo -e "${CYAN}==================================${RESET}"
echo ""

# ── Detect OS ──────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Darwin*) PLATFORM="macOS" ;;
  Linux*)  PLATFORM="Linux" ;;
  *)       fail "Unsupported OS: $OS" ;;
esac

info "Platform: $PLATFORM $(uname -m)"

# ── Check Node.js ──────────────────────────────────────
if ! command -v node &>/dev/null; then
  warn "Node.js not found. Installing via nvm..."

  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  nvm install --lts
  nvm use --lts
fi

NODE_VERSION=$(node --version)
NODE_MAJOR=$(echo "$NODE_VERSION" | tr -d 'v' | cut -d. -f1)

if (( NODE_MAJOR < 18 )); then
  fail "Node.js ≥18 required (found $NODE_VERSION)"
fi

ok "Node.js $NODE_VERSION"
ok "npm $(npm --version)"

# ── Install CLI ────────────────────────────────────────
echo ""
info "Installing blorq-cli globally..."

npm install -g blorq-cli --loglevel=error

ok "blorq-cli installed"

# ── Ensure npm bin in PATH ─────────────────────────────
NPM_PREFIX=$(npm config get prefix)
NPM_BIN="$NPM_PREFIX/bin"

if [[ ":$PATH:" != *":$NPM_BIN:"* ]]; then
  warn "npm global bin not in PATH"
  echo ""
  echo "Add this to your shell profile (~/.bashrc or ~/.zshrc):"
  echo "  export PATH=\"$NPM_BIN:\$PATH\""
  echo ""
fi

# ── First-time setup ───────────────────────────────────
echo ""
info "Running first-time setup..."

PORT="$PORT" DATA_DIR="$DATA_DIR" blorq setup

ok "Setup complete"

# ── Done ───────────────────────────────────────────────
echo ""
echo -e "${GREEN}  🚀 Blorq installed successfully!${RESET}"
echo ""
echo -e "  Start:        ${CYAN}blorq start${RESET}"
echo -e "  Dashboard:    ${CYAN}http://localhost:${PORT}${RESET}"
echo -e "  Login:        admin / admin123"
echo ""

warn "Change default password after login"

# ── Auto start prompt ──────────────────────────────────
if [ -t 1 ]; then
  read -rp "Start Blorq now? [Y/n] " REPLY
  REPLY="${REPLY:-Y}"

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    blorq start
  fi
fi