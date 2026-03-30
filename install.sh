#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
PLIST_NAME="com.local.claudestatusbar.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
BINARY="$REPO_DIR/.build/release/ClaudeStatusBar"

echo "==> Installing ClaudeStatusBar"

# 1. Check dependencies
if ! command -v jq &>/dev/null; then
  echo "error: 'jq' is required but not found. Install it with: brew install jq"
  exit 1
fi

if ! command -v swift &>/dev/null; then
  echo "error: 'swift' is required but not found. Install Xcode Command Line Tools: xcode-select --install"
  exit 1
fi

# 2. Install the hook
echo "==> Copying stop_hook.sh"
mkdir -p "$HOOKS_DIR"
cp "$REPO_DIR/hooks/stop_hook.sh" "$HOOKS_DIR/stop_hook.sh"
chmod +x "$HOOKS_DIR/stop_hook.sh"

# 3. Register the hook in settings.json
echo "==> Registering statusLine hook in $SETTINGS_FILE"
mkdir -p "$(dirname "$SETTINGS_FILE")"
if [ ! -f "$SETTINGS_FILE" ]; then
  echo '{}' > "$SETTINGS_FILE"
fi

# Merge statusLine key into existing settings
UPDATED=$(jq '. + {"statusLine": {"type": "command", "command": "~/.claude/hooks/stop_hook.sh"}}' "$SETTINGS_FILE")
echo "$UPDATED" > "$SETTINGS_FILE"

# 4. Build the binary
echo "==> Building ClaudeStatusBar (release)"
cd "$REPO_DIR"
swift build -c release

# 5. Set up LaunchAgent for auto-start
echo "==> Installing LaunchAgent"
mkdir -p "$LAUNCH_AGENTS_DIR"
sed "s/YOUR_USERNAME/$(whoami)/g" "$REPO_DIR/$PLIST_NAME" > "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo ""
echo "Done! ClaudeStatusBar is running in your menu bar."
echo "To uninstall, run: ./uninstall.sh"
