#!/bin/bash
# /opt/shua/worker.sh

BASE_DIR="/opt/shua"
CONFIG_FILE="$BASE_DIR/config.conf"
STATS_FILE="$BASE_DIR/stats.log"

# 如果统计文件不存在，则初始化
if [ ! -f "$STATS_FILE" ]; then
    echo -e "0\n0" > "$STATS_FILE"
fi

# 时间判断函数
check_time() {
    # 如果没有设置时间段，默认全天运行
    if [ -z "$TIME_WINDOWS" ]; then
        return 0
    fi
    
    current_time=$(date +%H%M)
    # 将逗号分隔的时间段解析为数组
    IFS=',' read -ra ADDR <<< "$TIME_WINDOWS"
    
    for window in "${ADDR[@]}"; do
        # 提取并去掉冒号，将 08:30 转换为 0830
        start_time=$(echo "$window" | cut -d'-' -f1 | tr -d ':')
        end_time=$(echo "$window" | cut -d'-' -f2 | tr -d ':')
        
        # 判断当前时间是否在区间内
        if [ "$current_time" -ge "$start_time" ] && [ "$current_time" -le "$end_time" ]; then
            return 0 # 在时间段内
        fi
    done
    
    return 1 # 不在任何时间段内
}

# 主循环
while true; do
    # 每次循环重新读取配置，确保面板修改即时生效
    source "$CONFIG_FILE"

    # 如果没有配置下载链接，休眠 30 秒后再次检查
    if [ -z "$DOWNLOAD_URL" ]; then
        sleep 30
        continue
    fi

    # 检查是否在允许的工作时间段内
    if check_time; then
        # 使用 curl 下载，将文件直接丢弃到 /dev/null (-o)，并静默输出 (-s)
        # 跟随重定向 (-L)，只获取下载的真实字节数 (-w "%{size_download}")
        bytes=$(curl -s -L --max-time 7200 -o /dev/null -w "%{size_download}" "$DOWNLOAD_URL")
        
        # 如果下载成功（获取到的字节数大于 0）
        if [ -n "$bytes" ] && [ "$bytes" -gt 0 ]; then
            # 读取当前统计数据
            { read count; read total_bytes; } < "$STATS_FILE"
            
            # 累加次数和字节数 (Bash 原生计算支持到极大的整数，处理 VPS 流量完全足够)
            count=$((count + 1))
            total_bytes=$((total_bytes + bytes))
            
            # 写入更新后的统计数据
            echo -e "$count\n$total_bytes" > "$STATS_FILE"
        fi
        
        # 下载完成后，休眠指定的间隔时间
        sleep "${INTERVAL:-60}"
    else
        # 不在工作时间内，休眠 60 秒后再次检查时间
        sleep 60
    fi
done
