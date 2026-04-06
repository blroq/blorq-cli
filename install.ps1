# Blorq — One-command installer for Windows (PowerShell)
# Usage:
#   iwr -useb https://raw.githubusercontent.com/blroq/blorq-cli/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

# ── Config ─────────────────────────────────────────────
$Port    = if ($env:PORT) { $env:PORT } else { "9900" }
$DataDir = if ($env:DATA_DIR) { $env:DATA_DIR } else { "$env:LOCALAPPDATA\blorq" }

# ── Helpers ────────────────────────────────────────────
function Write-Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Info($msg) { Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "  ✖ $msg" -ForegroundColor Red; exit 1 }

# ── Banner ─────────────────────────────────────────────
Write-Host ""
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host "        Blorq Log Aggregator        " -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""

# ── Check Node.js ──────────────────────────────────────
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Warn "Node.js not found"
    Write-Info "Opening Node.js download page..."
    Start-Process "https://nodejs.org"
    Write-Fail "Install Node.js 18+ and rerun"
}

$version = (node --version).TrimStart('v')
$major = [int]($version.Split('.')[0])

if ($major -lt 18) {
    Write-Fail "Node.js >=18 required (found $version)"
}

Write-Ok "Node.js v$version"
Write-Ok "npm $(npm --version)"

# ── Install CLI (GLOBAL) ───────────────────────────────
Write-Host ""
Write-Info "Installing blorq-cli globally..."

npm install -g blorq-cli --loglevel=error

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to install blorq-cli"
}

Write-Ok "blorq-cli installed"

# ── Ensure npm global bin in PATH ──────────────────────
$npmPrefix = npm config get prefix
$npmBin = "$npmPrefix"

if ($env:Path -notlike "*$npmBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$env:Path;$npmBin", "User")
    Write-Info "Added npm global bin to PATH"
    Write-Warn "Restart terminal if 'blorq' is not found"
}

# ── First-time setup ───────────────────────────────────
Write-Host ""
Write-Info "Running first-time setup..."

$env:PORT     = $Port
$env:DATA_DIR = $DataDir

blorq setup

if ($LASTEXITCODE -ne 0) {
    Write-Fail "Setup failed"
}

Write-Ok "Setup complete"

# ── Done ───────────────────────────────────────────────
Write-Host ""
Write-Host "  🚀 Blorq installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Start:        blorq start" -ForegroundColor Cyan
Write-Host "  Dashboard:    http://localhost:$Port" -ForegroundColor Cyan
Write-Host "  Login:        admin / admin123" -ForegroundColor Yellow
Write-Host ""
Write-Warn "Change default password after login"

# ── Auto start prompt ──────────────────────────────────
$start = Read-Host "Start Blorq now? [Y/n]"

if (-not $start -or $start -match "^[Yy]") {
    Write-Host ""
    blorq start
}