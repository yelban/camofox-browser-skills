#!/usr/bin/env bash
# Template: Multi-session isolation for parallel scraping
# Usage: bash multi-session.sh <url1> <url2> [url3...]
set -euo pipefail

CAMOFOX="bash ~/.claude/skills/camofox-browser/scripts/camofox.sh"
OUTPUT_DIR="/tmp/camofox-multi"

if [ $# -lt 2 ]; then
    echo "Usage: multi-session.sh <url1> <url2> [url3...]"
    echo "Each URL gets its own isolated session (separate cookies/storage)"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ── Open each URL in isolated session ──
SESSION_NUM=0
for URL in "$@"; do
    SESSION_NUM=$((SESSION_NUM + 1))
    SESSION="session-$SESSION_NUM"
    echo "[$SESSION] Opening: $URL"
    $CAMOFOX --session "$SESSION" open "$URL"
done

# ── Wait for pages to load ──
sleep 3

# ── Snapshot each session ──
SESSION_NUM=0
for URL in "$@"; do
    SESSION_NUM=$((SESSION_NUM + 1))
    SESSION="session-$SESSION_NUM"

    echo ""
    echo "=== [$SESSION] $URL ==="
    $CAMOFOX --session "$SESSION" snapshot > "$OUTPUT_DIR/$SESSION-snapshot.txt"
    $CAMOFOX --session "$SESSION" screenshot "$OUTPUT_DIR/$SESSION.png"
    echo "Saved: $OUTPUT_DIR/$SESSION-snapshot.txt"
    echo "Saved: $OUTPUT_DIR/$SESSION.png"
done

echo ""
echo "All sessions captured. Files:"
ls -la "$OUTPUT_DIR"

# ── Cleanup all sessions ──
echo ""
echo "Cleaning up..."
SESSION_NUM=0
for URL in "$@"; do
    SESSION_NUM=$((SESSION_NUM + 1))
    $CAMOFOX --session "session-$SESSION_NUM" close
done

echo "Done!"
