#!/usr/bin/env bash
# camofox-browser setup — one-time installation
set -euo pipefail

INSTALL_DIR="$HOME/.camofox-browser"
CAMOFOX_PORT="${CAMOFOX_PORT:-9377}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { echo "  [camofox] $*"; }
ok()    { echo "  [camofox] ✓ $*"; }
fail()  { echo "  [camofox] ✗ $*" >&2; exit 1; }

# ── Step 1: Check Node.js ──
info "Checking Node.js..."
if ! command -v node &>/dev/null; then
    fail "Node.js not found. Install with: brew install node"
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    fail "Node.js >= 18 required (found v$(node -v)). Update with: brew upgrade node"
fi
ok "Node.js $(node -v)"

# ── Step 2: Install @askjo/camofox-browser ──
if [ -d "$INSTALL_DIR/node_modules/@askjo/camofox-browser" ]; then
    info "Already installed at $INSTALL_DIR, updating..."
    cd "$INSTALL_DIR" && npm update @askjo/camofox-browser
else
    info "Installing @askjo/camofox-browser to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    npm init -y --silent 2>/dev/null || true
    npm install @askjo/camofox-browser
fi
ok "Package installed"

# ── Step 3: Create launch script ──
cat > "$INSTALL_DIR/start.sh" << 'LAUNCH_EOF'
#!/usr/bin/env bash
set -euo pipefail
INSTALL_DIR="$HOME/.camofox-browser"
export PORT="${CAMOFOX_PORT:-9377}"
cd "$INSTALL_DIR/node_modules/@askjo/camofox-browser"
exec node server.js
LAUNCH_EOF
chmod +x "$INSTALL_DIR/start.sh"
ok "Launch script created"

# ── Step 4: Make camofox.sh executable ──
chmod +x "$SCRIPT_DIR/camofox.sh"
ok "CLI wrapper ready"

# ── Step 5: Create state directories ──
mkdir -p /tmp/camofox-state
mkdir -p /tmp/camofox-screenshots
ok "State directories created"

# ── Step 6: First launch (downloads Camoufox browser ~300MB) ──
info "Starting server for first-time setup (downloads Camoufox browser)..."
info "This may take a few minutes on first run..."

export PORT="$CAMOFOX_PORT"
cd "$INSTALL_DIR/node_modules/@askjo/camofox-browser"
nohup node server.js > /tmp/camofox-state/server.log 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > /tmp/camofox-state/server.pid

# Wait for server to be ready (up to 120s for first download)
info "Waiting for server (port $CAMOFOX_PORT)..."
for i in $(seq 1 120); do
    if curl -sf "http://localhost:$CAMOFOX_PORT/health" &>/dev/null; then
        ok "Server running on port $CAMOFOX_PORT (PID: $SERVER_PID)"
        break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo ""
        echo "Server process died. Last 20 lines of log:"
        tail -20 /tmp/camofox-state/server.log 2>/dev/null || true
        fail "Server failed to start. Check /tmp/camofox-state/server.log"
    fi
    sleep 2
    printf "."
done

# Verify health
if ! curl -sf "http://localhost:$CAMOFOX_PORT/health" &>/dev/null; then
    fail "Server did not respond after 240s. Check /tmp/camofox-state/server.log"
fi

echo ""
ok "Setup complete!"
info "Usage: bash ~/.claude/skills/camofox-browser/scripts/camofox.sh <command>"
info "Or in Claude Code: camofox <command>"
