# ClaudeStatusBar

A native macOS menu bar app showing your Claude Code plan usage in real time.

```
⚡ 42%   ← 5-hour rate limit utilization, color-coded green / yellow / red
```

Click the icon to see a popover with context window %, session cost, and model name.

![img.png](preview.png)

## Requirements

- macOS 13+
- Swift 5.9+
- `jq` — `brew install jq`

## Setup

**1. Register the hook** — add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/stop_hook.sh"
  }
}
```

**2. Build and run:**

```bash
cd ~/ClaudeStatusBar
swift build -c release
.build/release/ClaudeStatusBar
```

**3. Auto-start on login (optional):**

```bash
launchctl load ~/Library/LaunchAgents/com.local.claudestatusbar.plist
# To stop:
launchctl unload ~/Library/LaunchAgents/com.local.claudestatusbar.plist
```

## How it works

- **Menu bar %** — fetched from the Anthropic OAuth API every minute using your stored Claude Code credentials
- **Popover details** — written by `~/.claude/hooks/stop_hook.sh` after every Claude response, watched via `DispatchSource`
- **Stale indicator** — label dims if no response has been received in the last 5 minutes

## Troubleshooting

| Symptom | Fix |
|---|---|
| Icon shows `--` | Normal at startup — populates within seconds. If it persists, run `claude /login` |
| 5-hour % never changes | Re-authenticate: `claude /login` |
| Popover data doesn't update | Check the hook is registered in `settings.json` and `jq` is installed |
