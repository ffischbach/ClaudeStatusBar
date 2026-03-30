#!/bin/bash
set -euo pipefail

PLIST_NAME="com.local.claudestatusbar.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "==> Uninstalling ClaudeStatusBar"

# Stop and remove LaunchAgent
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_NAME" ]; then
  launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
  rm "$LAUNCH_AGENTS_DIR/$PLIST_NAME"
  echo "==> Removed LaunchAgent"
fi

# Remove hook
if [ -f "$HOME/.claude/hooks/stop_hook.sh" ]; then
  rm "$HOME/.claude/hooks/stop_hook.sh"
  echo "==> Removed stop_hook.sh"
fi

# Remove statusLine entry from settings.json
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  UPDATED=$(jq 'del(.statusLine)' "$SETTINGS_FILE")
  echo "$UPDATED" > "$SETTINGS_FILE"
  echo "==> Removed statusLine from $SETTINGS_FILE"
fi

echo ""
echo "Done. Build artifacts in .build/ were left in place — remove manually if needed."
