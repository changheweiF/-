#!/bin/sh

# =======================
#   Campus Login Script
#   Version: 6.x
# =======================

# === 用户配置区（需要自行填写）===
USERNAME="your_username_here"
PASSWORD="your_password_here"
LOGIN_URL="http://110.188.xx.xx:801/eportal/portal/login"   # 替换成学校认证地址
SUCCESS_FLAG='"result":"1"'

# === 运行配置 ===
LOG_FILE="/var/log/campus-login.log"
LOG_MAX=10240   # 10MB
CHECK_INTERVAL=30
REAUTH_INTERVAL=3600   # 一小时强制重认证（可自行调整）
LAST_AUTH_FILE="/tmp/campus-last-auth"

# 日志函数
log(){
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    size=$(wc -c < "$LOG_FILE")
    [ "$size" -gt "$LOG_MAX" ] && echo "" > "$LOG_FILE"
}

# 检查网络状态
check_network(){
    ping -c 1 -W 1 223.5.5.5 >/dev/null 2>&1 && return 0
    curl -s --max-time 2 https://www.baidu.com >/dev/null 2>&1 && return 0
    return 1
}

# DHCP 续租检查（适配 OpenWrt udhcpc）
check_dhcp(){
    ps | grep '[u]dhcpc' >/dev/null || {
        log "DHCP 可能掉线，正在重启 WAN..."
        ifup wan
        sleep 3
    }
}

# 登录
do_login(){
    log "尝试登录校园网..."

    RESPONSE=$(curl -s -d "userId=$USERNAME&password=$PASSWORD" "$LOGIN_URL")

    echo "$RESPONSE" | grep -q "$SUCCESS_FLAG"
    if [ $? -eq 0 ]; then
        echo "$(date +%s)" > "$LAST_AUTH_FILE"
        log "✔ 登录成功"
        return 0
    else
        FRAG=$(echo "$RESPONSE" | head -c 80)
        log "❌ 登录失败 | 响应片段: $FRAG"
        return 1
    fi
}

# 主循环
main_loop(){
    log "校园网自动登录服务已启动"
    [ ! -f "$LAST_AUTH_FILE" ] && echo 0 > "$LAST_AUTH_FILE"

    while true; do
        NOW=$(date +%s)
        LAST=$(cat "$LAST_AUTH_FILE")
        DIFF=$((NOW - LAST))

        check_dhcp

        if [ $DIFF -ge $REAUTH_INTERVAL ]; then
            log "达到强制重认证时间（${DIFF}s），正在重新登录..."
            do_login
        else
            if ! check_network; then
                log "检测到无网络，正在重新登录..."
                do_login
            fi
        fi

        sleep $CHECK_INTERVAL
    done
}

main_loop
