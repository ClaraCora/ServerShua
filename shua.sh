#!/bin/bash
# /opt/shua/shua.sh

BASE_DIR="/opt/shua"
CONFIG_FILE="$BASE_DIR/config.conf"
STATS_FILE="$BASE_DIR/stats.log"

# 确保配置文件存在
[ ! -f "$CONFIG_FILE" ] && touch "$CONFIG_FILE"

# 字节转 GB 的函数 (保留三位小数)
bytes_to_gb() {
    local bytes=$1
    if [ -z "$bytes" ]; then bytes=0; fi
    # 1 GB = 1073741824 bytes (1024^3)
    awk "BEGIN {printf \"%.3f\", $bytes / 1073741824}"
}

# 主菜单循环
while true; do
    clear
    echo "=========================================="
    echo "       VPS 流量消耗与定时下载助手"
    echo "=========================================="
    
    # 检查 Systemd 服务状态
    if systemctl is-active --quiet shua.service 2>/dev/null; then
        status="\e[32m运行中\e[0m"
    else
        status="\e[31m已停止\e[0m"
    fi
    echo -e "  后台服务状态: $status"

    # 读取统计数据
    if [ -f "$STATS_FILE" ]; then
        count=$(sed -n '1p' "$STATS_FILE")
        total_bytes=$(sed -n '2p' "$STATS_FILE")
        
        # 处理空文件异常
        [ -z "$count" ] && count=0
        [ -z "$total_bytes" ] && total_bytes=0
        
        total_gb=$(bytes_to_gb "$total_bytes")
    else
        count=0
        total_gb="0.000"
    fi
    
    echo "  总下载次数  : $count 次"
    echo "  总消耗流量  : $total_gb G"
    echo "=========================================="
    
    # 读取最新配置以便在菜单中显示当前值
    source "$CONFIG_FILE"
    
    echo "  1. 设置下载链接 (当前: ${DOWNLOAD_URL:-未设置})"
    echo "  2. 设置休眠间隔 (当前: ${INTERVAL:-60} 秒)"
    echo "  3. 设置工作时间 (当前: ${TIME_WINDOWS:-全天 24 小时运行})"
    echo "  ----------------------------------------"
    echo "  4. 启动 / 重启后台服务"
    echo "  5. 停止后台服务"
    echo "  0. 退出面板"
    echo "=========================================="
    read -p "请输入选项 [0-5]: " choice
    
    case $choice in
        1)
            echo ""
            read -p "请输入新的下载链接 (直接回车取消): " new_url
            if [ -n "$new_url" ]; then
                # 替换或追加配置
                if grep -q "^DOWNLOAD_URL=" "$CONFIG_FILE"; then
                    sed -i "s|^DOWNLOAD_URL=.*|DOWNLOAD_URL=\"$new_url\"|" "$CONFIG_FILE"
                else
                    echo "DOWNLOAD_URL=\"$new_url\"" >> "$CONFIG_FILE"
                fi
                echo -e "\e[32m[成功] 下载链接已更新！\e[0m"
                sleep 1.5
            fi
            ;;
        2)
            echo ""
            read -p "请输入下载间隔(秒) (必须是数字，直接回车取消): " new_interval
            if [[ "$new_interval" =~ ^[0-9]+$ ]]; then
                if grep -q "^INTERVAL=" "$CONFIG_FILE"; then
                    sed -i "s|^INTERVAL=.*|INTERVAL=$new_interval|" "$CONFIG_FILE"
                else
                    echo "INTERVAL=$new_interval" >> "$CONFIG_FILE"
                fi
                echo -e "\e[32m[成功] 下载间隔已更新！\e[0m"
                sleep 1.5
            elif [ -n "$new_interval" ]; then
                echo -e "\e[31m[错误] 请输入纯数字！\e[0m"
                sleep 1.5
            fi
            ;;
        3)
            echo ""
            echo "格式示例: 08:00-12:00,14:00-18:00"
            echo "提示: 输入 'clear' 可清空时间限制，恢复全天运行。"
            read -p "请输入工作时间段 (直接回车取消): " new_time
            if [ "$new_time" == "clear" ]; then
                sed -i "s|^TIME_WINDOWS=.*|TIME_WINDOWS=\"\"|" "$CONFIG_FILE"
                echo -e "\e[32m[成功] 已清空时间段，当前为全天运行！\e[0m"
                sleep 1.5
            elif [ -n "$new_time" ]; then
                if grep -q "^TIME_WINDOWS=" "$CONFIG_FILE"; then
                    sed -i "s|^TIME_WINDOWS=.*|TIME_WINDOWS=\"$new_time\"|" "$CONFIG_FILE"
                else
                    echo "TIME_WINDOWS=\"$new_time\"" >> "$CONFIG_FILE"
                fi
                echo -e "\e[32m[成功] 工作时间已更新！\e[0m"
                sleep 1.5
            fi
            ;;
        4)
            echo ""
            systemctl daemon-reload
            systemctl restart shua.service
            systemctl enable shua.service >/dev/null 2>&1
            echo -e "\e[32m[成功] 后台服务已启动并设置为开机自启！\e[0m"
            sleep 1.5
            ;;
        5)
            echo ""
            systemctl stop shua.service
            systemctl disable shua.service >/dev/null 2>&1
            echo -e "\e[32m[成功] 后台服务已停止并取消开机自启！\e[0m"
            sleep 1.5
            ;;
        0)
            clear
            exit 0
            ;;
        *)
            echo -e "\e[31m无效选项，请重新输入。\e[0m"
            sleep 1
            ;;
    esac
done
