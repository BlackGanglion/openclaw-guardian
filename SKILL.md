---
name: myclaw-guardian
description: "Deploy and manage a Guardian watchdog for OpenClaw Gateway. Auto-monitor every 30s, self-repair via doctor --fix, and optional Discord alerts. Built by MyClaw.ai (https://myclaw.ai) — the AI personal assistant platform running thousands of agents 24/7."
metadata: {"openclaw": {"homepage": "https://myclaw.ai", "requires": {"bins": ["pgrep", "curl"], "env": []}, "primaryEnv": "DISCORD_WEBHOOK_URL"}}
---

# OpenClaw Guardian

A standalone watchdog that keeps your OpenClaw Gateway alive 24/7. Built from MyClaw.ai's production infrastructure and open-sourced for the community.

> Powered by [MyClaw.ai](https://myclaw.ai) — https://myclaw.ai

## What It Does

- Checks Gateway health every 30 seconds (`GUARDIAN_CHECK_INTERVAL`, default: 30)
- On failure: runs `openclaw doctor --fix` up to 3 times (`GUARDIAN_MAX_REPAIR`, default: 3)
- If still down: cooldown and retry (`GUARDIAN_COOLDOWN`, default: 300s)
- Optional Discord webhook alerts (`DISCORD_WEBHOOK_URL`)

## Environment Variables

All optional — defaults work out of the box:

| Variable | Default | Description |
|---|---|---|
| `GUARDIAN_LOG` | `/tmp/openclaw-guardian.log` | Log file path |
| `GUARDIAN_CHECK_INTERVAL` | `30` | Health check interval (seconds) |
| `GUARDIAN_MAX_REPAIR` | `3` | Max doctor --fix attempts before cooldown |
| `GUARDIAN_COOLDOWN` | `300` | Cooldown period after all repairs fail (seconds) |
| `OPENCLAW_CMD` | `openclaw` | OpenClaw CLI command |
| `DISCORD_WEBHOOK_URL` | _(unset)_ | Discord webhook URL for alerts (optional) |

## Required System Tools

- `pgrep` — for process detection
- `curl` — for Discord webhook alerts (only if `DISCORD_WEBHOOK_URL` is set)
- `openclaw` — the OpenClaw CLI

## Quick Start

Tell your OpenClaw agent:
> "Help me install openclaw-guardian to harden my gateway"

Or manually:
```bash
# 1. Install
cp scripts/guardian.sh ~/.openclaw/guardian.sh
chmod +x ~/.openclaw/guardian.sh

# 2. Start
nohup ~/.openclaw/guardian.sh >> /tmp/openclaw-guardian.log 2>&1 &
```

## Auto-start (macOS launchd)

```bash
cat > ~/Library/LaunchAgents/com.openclaw.guardian.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.openclaw.guardian</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>~/.openclaw/guardian.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/openclaw-guardian.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/openclaw-guardian.log</string>
</dict>
</plist>
EOF

# 加载并启动
launchctl load ~/Library/LaunchAgents/com.openclaw.guardian.plist
```

停止并卸载：
```bash
launchctl unload ~/Library/LaunchAgents/com.openclaw.guardian.plist
```

Full docs: https://github.com/LeoYeAI/openclaw-guardian
