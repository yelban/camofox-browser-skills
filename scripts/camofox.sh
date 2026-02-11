#!/usr/bin/env bash
# camofox — CLI wrapper for camofox-browser REST API
set -euo pipefail

# ── Configuration ──
CAMOFOX_PORT="${CAMOFOX_PORT:-9377}"
CAMOFOX_SESSION="${CAMOFOX_SESSION:-default}"
CAMOFOX_BASE="http://localhost:$CAMOFOX_PORT"
STATE_DIR="/tmp/camofox-state"
SCREENSHOT_DIR="/tmp/camofox-screenshots"
INSTALL_DIR="$HOME/.camofox-browser"

# ── Parse global flags ──
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --session)
            CAMOFOX_SESSION="$2"
            shift 2
            ;;
        --port)
            CAMOFOX_PORT="$2"
            CAMOFOX_BASE="http://localhost:$CAMOFOX_PORT"
            shift 2
            ;;
        *)
            echo "Unknown flag: $1" >&2
            exit 1
            ;;
    esac
done

COMMAND="${1:-help}"
shift || true

# ── State files ──
TAB_FILE="$STATE_DIR/${CAMOFOX_SESSION}.tab"
USER_ID="camofox-${CAMOFOX_SESSION}"

# ── Helpers ──
api() {
    local method="$1" path="$2"
    shift 2
    curl -sf -X "$method" \
        -H "Content-Type: application/json" \
        "$CAMOFOX_BASE$path" "$@"
}

api_json() {
    local method="$1" path="$2" body="$3"
    curl -sf -X "$method" \
        -H "Content-Type: application/json" \
        -d "$body" \
        "$CAMOFOX_BASE$path"
}

get_active_tab() {
    if [ -f "$TAB_FILE" ]; then
        cat "$TAB_FILE"
    else
        echo ""
    fi
}

set_active_tab() {
    mkdir -p "$STATE_DIR"
    echo "$1" > "$TAB_FILE"
}

require_active_tab() {
    local tab
    tab=$(get_active_tab)
    if [ -z "$tab" ]; then
        echo "No active tab. Use 'camofox open <url>' first." >&2
        exit 1
    fi
    echo "$tab"
}

strip_ref() {
    # Strip @ prefix: @e1 → e1
    echo "${1#@}"
}

ensure_server_running() {
    if curl -sf "$CAMOFOX_BASE/health" &>/dev/null; then
        return 0
    fi

    # Check if install exists
    if [ ! -f "$INSTALL_DIR/start.sh" ]; then
        echo "camofox-browser not installed. Run:" >&2
        echo "  bash ~/.claude/skills/camofox-browser/scripts/setup.sh" >&2
        exit 1
    fi

    echo "Starting camofox server on port $CAMOFOX_PORT..." >&2
    mkdir -p "$STATE_DIR"
    export PORT="$CAMOFOX_PORT"
    cd "$INSTALL_DIR/node_modules/@askjo/camofox-browser"
    nohup node server.js > "$STATE_DIR/server.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$STATE_DIR/server.pid"

    # Wait up to 60s
    for _ in $(seq 1 30); do
        if curl -sf "$CAMOFOX_BASE/health" &>/dev/null; then
            echo "Server started (PID: $pid)" >&2
            return 0
        fi
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "Server failed to start. Check $STATE_DIR/server.log" >&2
            exit 1
        fi
        sleep 2
    done

    echo "Server start timed out. Check $STATE_DIR/server.log" >&2
    exit 1
}

# ── Commands ──
case "$COMMAND" in

# ── Server Control ──
start)
    ensure_server_running
    echo "Server running on port $CAMOFOX_PORT"
    ;;

stop)
    if [ -f "$STATE_DIR/server.pid" ]; then
        PID=$(cat "$STATE_DIR/server.pid")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            echo "Server stopped (PID: $PID)"
        else
            echo "Server not running (stale PID: $PID)"
        fi
        rm -f "$STATE_DIR/server.pid"
    else
        echo "No PID file found. Server may not be running."
    fi
    ;;

health)
    ensure_server_running
    api GET /health
    echo ""
    ;;

# ── Tab Creation + Navigation ──
open|goto)
    URL="${1:?Usage: camofox open <url>}"
    ensure_server_running

    # Create tab
    RESPONSE=$(api_json POST /tabs \
        "{\"userId\":\"$USER_ID\",\"sessionKey\":\"$CAMOFOX_SESSION\",\"url\":\"$URL\"}")

    # Extract tabId from response
    TAB_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tabId',''))" 2>/dev/null || echo "")

    if [ -z "$TAB_ID" ]; then
        echo "Failed to create tab. Response: $RESPONSE" >&2
        exit 1
    fi

    set_active_tab "$TAB_ID"
    echo "Opened: $URL"
    echo "Tab: $TAB_ID"
    ;;

navigate)
    URL="${1:?Usage: camofox navigate <url>}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/navigate" \
        "{\"userId\":\"$USER_ID\",\"url\":\"$URL\"}"
    echo ""
    ;;

# ── Page State ──
snapshot)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    RESPONSE=$(api GET "/tabs/$TAB_ID/snapshot?userId=$USER_ID")

    # Pretty-print the snapshot text
    SNAPSHOT=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('snapshot', ''))
print()
print('URL:', data.get('url', ''))
" 2>/dev/null || echo "$RESPONSE")
    echo "$SNAPSHOT"
    ;;

screenshot)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    mkdir -p "$SCREENSHOT_DIR"

    OUTPUT_PATH="${1:-$SCREENSHOT_DIR/camofox-$(date +%Y%m%d-%H%M%S).png}"

    # API returns raw PNG binary
    curl -sf -o "$OUTPUT_PATH" \
        "$CAMOFOX_BASE/tabs/$TAB_ID/screenshot?userId=$USER_ID"

    if [ -f "$OUTPUT_PATH" ] && [ -s "$OUTPUT_PATH" ]; then
        echo "Screenshot saved: $OUTPUT_PATH"
    else
        echo "Failed to capture screenshot" >&2
        exit 1
    fi
    ;;

tabs)
    ensure_server_running
    RESPONSE=$(api GET "/tabs?userId=$USER_ID")
    echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tabs = data if isinstance(data, list) else data.get('tabs', [])
if not tabs:
    print('No open tabs')
else:
    for t in tabs:
        tid = t.get('tabId', t.get('id', '?'))
        url = t.get('url', '?')
        print(f'  {tid}  {url}')
" 2>/dev/null || echo "$RESPONSE"
    ;;

# ── Interaction ──
click)
    REF="${1:?Usage: camofox click @e1}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    REF_CLEAN=$(strip_ref "$REF")
    api_json POST "/tabs/$TAB_ID/click" \
        "{\"userId\":\"$USER_ID\",\"ref\":\"$REF_CLEAN\"}"
    echo "Clicked: $REF"
    ;;

type)
    REF="${1:?Usage: camofox type @e1 \"text\"}"
    TEXT="${2:?Usage: camofox type @e1 \"text\"}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    REF_CLEAN=$(strip_ref "$REF")
    # Escape text for JSON safely via python3
    BODY=$(python3 -c "
import json, sys
print(json.dumps({
    'userId': sys.argv[1],
    'ref': sys.argv[2],
    'text': sys.argv[3]
}))
" "$USER_ID" "$REF_CLEAN" "$TEXT")
    api_json POST "/tabs/$TAB_ID/type" "$BODY"
    echo "Typed into $REF: $TEXT"
    ;;

scroll)
    DIRECTION="${1:-down}"
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/scroll" \
        "{\"userId\":\"$USER_ID\",\"direction\":\"$DIRECTION\"}"
    echo "Scrolled $DIRECTION"
    ;;

# ── Navigation ──
back)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/back" "{\"userId\":\"$USER_ID\"}"
    echo "Navigated back"
    ;;

forward)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/forward" "{\"userId\":\"$USER_ID\"}"
    echo "Navigated forward"
    ;;

refresh)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api_json POST "/tabs/$TAB_ID/refresh" "{\"userId\":\"$USER_ID\"}"
    echo "Page refreshed"
    ;;

# ── Search Macros ──
search)
    MACRO="${1:?Usage: camofox search google \"query\"}"
    QUERY="${2:?Usage: camofox search google \"query\"}"
    TAB_ID=$(get_active_tab)
    ensure_server_running

    # Create tab if none active
    if [ -z "$TAB_ID" ]; then
        RESPONSE=$(api_json POST /tabs \
            "{\"userId\":\"$USER_ID\",\"sessionKey\":\"$CAMOFOX_SESSION\"}")
        TAB_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tabId',''))" 2>/dev/null || echo "")
        if [ -z "$TAB_ID" ]; then
            echo "Failed to create tab" >&2
            exit 1
        fi
        set_active_tab "$TAB_ID"
    fi

    # Normalize macro name: "google" → "@google_search"
    case "$MACRO" in
        @*) MACRO_FULL="$MACRO" ;;
        *)  MACRO_FULL="@${MACRO}_search" ;;
    esac

    BODY=$(python3 -c "
import json, sys
print(json.dumps({
    'userId': sys.argv[1],
    'macro': sys.argv[2],
    'query': sys.argv[3]
}))
" "$USER_ID" "$MACRO_FULL" "$QUERY")

    api_json POST "/tabs/$TAB_ID/navigate" "$BODY"
    echo "Searched $MACRO_FULL: $QUERY"
    ;;

# ── Tab Cleanup ──
close)
    TAB_ID=$(get_active_tab)
    if [ -n "$TAB_ID" ]; then
        ensure_server_running
        api DELETE "/tabs/$TAB_ID?userId=$USER_ID" || true
        rm -f "$TAB_FILE"
        echo "Closed tab: $TAB_ID"
    else
        echo "No active tab to close"
    fi
    ;;

close-all)
    ensure_server_running
    api DELETE "/sessions/$USER_ID" || true
    rm -f "$STATE_DIR/${CAMOFOX_SESSION}".tab
    echo "Closed all tabs for session: $CAMOFOX_SESSION"
    ;;

# ── Links ──
links)
    TAB_ID=$(require_active_tab)
    ensure_server_running
    api GET "/tabs/$TAB_ID/links?userId=$USER_ID"
    echo ""
    ;;

# ── Help ──
help|--help|-h)
    cat << 'HELP'
camofox — Anti-detection browser automation (Camoufox)

USAGE:
  camofox [--session NAME] [--port PORT] <command> [args]

SERVER:
  start                       Start server (usually auto)
  stop                        Stop server
  health                      Health check

NAVIGATION:
  open <url>                  Open URL in new tab
  navigate <url>              Navigate current tab
  back / forward / refresh    History navigation
  scroll [down|up]            Scroll page

PAGE STATE:
  snapshot                    Accessibility snapshot with @refs
  screenshot [path]           Save screenshot
  tabs                        List open tabs
  links                       Get page links

INTERACTION:
  click @e1                   Click element by ref
  type @e1 "text"             Type into element

SEARCH:
  search google "query"       Google search (13 macros available)
  search youtube "query"      YouTube search

CLEANUP:
  close                       Close current tab
  close-all                   Close all tabs

OPTIONS:
  --session NAME              Use named session (default: "default")
  --port PORT                 Server port (default: 9377)

ENVIRONMENT:
  CAMOFOX_PORT                Server port (default: 9377)
  CAMOFOX_SESSION             Default session name
  HTTPS_PROXY                 Proxy server
HELP
    ;;

*)
    echo "Unknown command: $COMMAND" >&2
    echo "Run 'camofox help' for usage." >&2
    exit 1
    ;;
esac
