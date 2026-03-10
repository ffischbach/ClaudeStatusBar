# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: ClaudeStatusBar

A native macOS menu bar app showing Claude Code token usage. See full docs at `~/ClaudeStatusBar/README.md`.

## Key files

| File | Purpose |
|---|---|
| `~/ClaudeStatusBar/` | Swift/SwiftUI app (SPM, macOS 13+) |
| `~/.claude/hooks/stop_hook.sh` | statusLine command — writes session_usage.json, outputs terminal status |
| `~/.claude/settings.json` | Registers the statusLine command |
| `~/.claude/session_usage.json` | Live data file consumed by the app |
| `~/Library/LaunchAgents/com.local.claudestatusbar.plist` | Optional auto-start |

## Build & run

```bash
cd ~/ClaudeStatusBar
swift build          # debug
swift build -c release
swift run            # or: .build/release/ClaudeStatusBar
```

## Architecture

Two data sources feed the app:
1. Claude Code's `statusLine` command writes atomic JSON → DispatchSource file watcher detects change → SwiftUI re-renders (session/context data)
2. `UsageWatcher` polls `https://api.anthropic.com/api/oauth/usage` every 1 min via stored OAuth token → provides 5-hour and 7-day plan utilization

Four source files in `Sources/ClaudeStatusBar/`:
- `ClaudeStatusBarApp.swift` — `@main`, MenuBarExtra, menu bar label (`bolt.fill` icon + 5h plan %)
- `UsageWatcher.swift` — `@MainActor` ObservableObject, file watching, staleness timer (5 min), OAuth plan usage polling
- `TokenUsage.swift` — Codable models: `TokenUsage` (session data) and `PlanUsage` (5h/7d quota)
- `TokenUsageView.swift` — Popover UI; two states: data loaded vs. empty

Color thresholds (applied to 5-hour plan utilization): green < 50%, yellow 50–79%, red ≥ 80%.

## Data sources and what each field means

All data originates from Claude Code's `statusLine` hook, which fires after every response and pipes JSON into `stop_hook.sh`. The hook writes it atomically to `~/.claude/session_usage.json`.

**Menu bar label** — sourced from OAuth plan API (`PlanUsage.fiveHour.utilPct`):

| UI element | Source | What it is |
|---|---|---|
| `⚡` bolt color | `plan_usage.five_hour.utilization` | Green/yellow/red based on 5h quota fill |
| `42%` text | `plan_usage.five_hour.utilization` | % of 5-hour rate limit consumed |

**Popover** — sourced from `session_usage.json` (statusLine hook):

| UI field | JSON field | What it actually is |
|---|---|---|
| Context Window % | `context_window.used_percentage` | Current fill of this conversation's context window |
| In Context (tokens) | computed | `used_percentage / 100 * max_tokens` |
| Max Context | `context_window.max_tokens` | Context window size; defaults to 200,000 if absent |
| Session Cost | `cost.total_cost_usd` | Cumulative cost of this conversation so far |
| Model | `model.display_name` | Model used in the last response |

**What the hook does NOT provide:**
- `context_window.total_input_tokens` / `total_output_tokens` are cumulative counters (not current context snapshot) — not displayed as they can exceed `max_tokens` and are misleading

**Staleness:** the app shows an "idle" badge and dims after 5 minutes of no hook invocations (no active Claude Code session).

## Critical design decisions

- **statusLine command** (not Stop hooks) is the correct hook type — it receives `context_window`, `cost`, `model` data
- **Watch the directory** (`~/.claude/`) not the file — atomic `mv` rename events only fire on the parent dir
- `keyDecodingStrategy = .convertFromSnakeCase` — JSON is snake_case, Swift model is camelCase

## settings.json hook registration

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/stop_hook.sh"
  }
}
```

## Testing the hook manually

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6","id":"claude-sonnet-4-6"},"context_window":{"used_percentage":42.5,"total_input_tokens":85000,"total_output_tokens":3000},"cost":{"total_cost_usd":0.0312}}' \
  | ~/.claude/hooks/stop_hook.sh
cat ~/.claude/session_usage.json | jq .
```
