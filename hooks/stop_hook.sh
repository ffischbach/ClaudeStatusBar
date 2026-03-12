#!/bin/bash
# statusLine command: receives rich context data from Claude Code,
# writes it to session_usage.json for ClaudeStatusBar, and outputs a statusline.

INPUT=$(cat)
USAGE_FILE="$HOME/.claude/session_usage.json"
TMP_FILE="${USAGE_FILE}.tmp.$$"

# Write data for menu bar app (atomic rename)
printf '%s' "$INPUT" | /usr/bin/jq \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '. + {captured_at: $ts}' \
  > "$TMP_FILE" && mv "$TMP_FILE" "$USAGE_FILE" 2>/dev/null || true

# Output statusline text for Claude Code terminal display
context_pct=$(printf '%s' "$INPUT" | /usr/bin/jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(printf '%s' "$INPUT" | /usr/bin/jq -r '.cost.total_cost_usd // 0')
model=$(printf '%s' "$INPUT" | /usr/bin/jq -r '.model.display_name // "Claude"')
printf '%s | ctx %s%% | $%.4f\n' "$model" "$context_pct" "$cost"
