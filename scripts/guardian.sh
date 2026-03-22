#!/bin/bash
# guardian.sh - OpenClaw Guardian 守护进程
# 功能：监控 Gateway → doctor --fix → Discord 通知
# 用法：chmod +x guardian.sh && nohup ./guardian.sh >> /tmp/openclaw-guardian.log 2>&1 &

LOG_FILE="${GUARDIAN_LOG:-/tmp/openclaw-guardian.log}"
CHECK_INTERVAL="${GUARDIAN_CHECK_INTERVAL:-30}"      # 检测间隔(秒)
MAX_REPAIR_ATTEMPTS="${GUARDIAN_MAX_REPAIR:-3}"      # 连续修复最大次数
COOLDOWN_PERIOD="${GUARDIAN_COOLDOWN:-300}"          # 失败后冷却期(秒)
OPENCLAW_CMD="${OPENCLAW_CMD:-openclaw}"
DISCORD_WEBHOOK="${DISCORD_WEBHOOK_URL:-}"           # 可选，设置环境变量启用通知
PIDFILE="${GUARDIAN_PIDFILE:-/tmp/openclaw-guardian.pid}"

# 防止重复启动
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Guardian 已在运行 (PID: $(cat "$PIDFILE"))，退出"
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 发送 Discord 通知（可选）
notify() {
    local msg="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -X POST "$DISCORD_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"🚨 **OpenClaw Guardian**: $msg\"}" \
            >/dev/null 2>&1 || true
    fi
    log "[NOTIFY] $msg"
}

# 检查 Gateway 是否运行
is_gateway_running() {
    if $OPENCLAW_CMD gateway health >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# 主修复流程
repair_gateway() {
    local attempt=0
    notify "Gateway 异常，开始修复流程..."

    while [ $attempt -lt $MAX_REPAIR_ATTEMPTS ]; do
        attempt=$((attempt + 1))

        # 每次修复前再次确认 Gateway 状态，已恢复则跳过
        if is_gateway_running; then
            notify "✅ Gateway 已自行恢复，跳过修复"
            return 0
        fi

        notify "修复尝试 $attempt/$MAX_REPAIR_ATTEMPTS，执行 doctor --fix..."
        $OPENCLAW_CMD doctor --fix >> "$LOG_FILE" 2>&1
        sleep 10

        if is_gateway_running; then
            notify "✅ doctor --fix 修复成功（第 $attempt 次尝试），Gateway 已恢复"
            return 0
        fi
        sleep 10
    done

    # 最终：冷却
    notify "❌ doctor --fix 修复失败（共 $MAX_REPAIR_ATTEMPTS 次），冷却 ${COOLDOWN_PERIOD}s 后继续监控"
    log "进入冷却期 ${COOLDOWN_PERIOD}s"
    sleep "$COOLDOWN_PERIOD"
}

# ===== 主循环 =====
log "🚀 Guardian 守护进程启动 (check=${CHECK_INTERVAL}s, max_repair=${MAX_REPAIR_ATTEMPTS})"
notify "Guardian 守护进程已启动"

while true; do
    if is_gateway_running; then
        notify "✅ Gateway 运行正常"
    else
        repair_gateway
    fi

    sleep "$CHECK_INTERVAL"
done
