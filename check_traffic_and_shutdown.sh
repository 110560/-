#!/bin/bash
# 兼容 vnStat 1.18 2.6
# 检查是否安装了 bc 工具
if ! command -v bc &> /dev/null; then
    echo "bc 工具未安装。请先安装 bc 工具。"
    exit 1
fi

# 检查是否安装了 vnstat 工具
if ! command -v vnstat &> /dev/null; then
    echo "vnstat 工具未安装。请先安装 vnstat 工具。"
    exit 1
fi

# 获取当前月份
current_month=$(date +'%Y-%m')

# 提醒文件路径
reminder_file="/var/tmp/reminder_sent_$current_month"

# 获取外网 IP
external_ip=$(curl -s ifconfig.me)

# 获取当前日期和时间
current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

# Telegram Bot API Token
bot_token="5162966701:AAGFVyYWQ45A_eaSYi4XlVYDvHzZ6frSmXQ"
# Chat ID
chat_id="461449457"

# 使用 vnstat 获取当前月份的出站流量
tx_line=$(vnstat -m | awk -v month="$(date +'%Y-%m')" '$1 ~ month')

# 检查是否获取到有效的流量数据
if [[ -z "$tx_line" ]]; then
    echo "未能找到当前月份的流量数据，请检查 vnstat 输出。"
    exit 1
fi

# 解析出站流量的数值和单位
tx_value=$(echo "$tx_line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^(TiB|GiB|MiB|KiB|B)$/) {print $(i-1); exit}}')
tx_unit=$(echo "$tx_line" | awk '{for(i=1;i<=NF;i++) if($i ~ /^(TiB|GiB|MiB|KiB|B)$/) {print $i; exit}}')

# 检查解析结果
if [[ -z "$tx_value" || -z "$tx_unit" ]]; then
    echo "无法解析流量数值或单位，请检查脚本和 vnstat 输出。"
    exit 1
fi

# 如果单位是 GiB，转换为 TiB
if [[ "$tx_unit" == "GiB" ]]; then
    tx_value=$(echo "scale=2; $tx_value / 1024" | bc | awk '{printf "%.2f", $0}')
    tx_unit="TiB"
fi

# 打印当前出站流量和关机阈值的比较
echo "当前出站流量为 $tx_value $tx_unit，未达到关机阈值 1.97 TiB。"

# 检查单位是否为 TiB
if [[ "$tx_unit" == "TiB" ]]; then
    # 修改提醒阈值
    threshold="1.90"
    # 修改关机阈值
    shutdown_threshold="1.97"

    # 检查是否达到提醒阈值 1.90 TiB
    if (( $(echo "$tx_value >= $threshold" | bc -l) )) && [[ ! -f "$reminder_file" ]]; then
        # 发送提醒消息到 Telegram
        message="出站流量已达到 $threshold TiB。外网 IP: $external_ip 时间: $current_datetime"
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
             -d chat_id="${chat_id}" \
             -d text="${message}"

        # 创建提醒文件
        touch "$reminder_file"
    fi

    # 检查是否达到关机阈值 1.97 TiB
    if (( $(echo "$tx_value >= $shutdown_threshold" | bc -l) )); then
        # 发送关机提醒消息到 Telegram
        shutdown_message="服务器即将关机！出站流量已达到 $shutdown_threshold TiB。外网 IP: $external_ip 时间: $current_datetime"
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
             -d chat_id="${chat_id}" \
             -d text="${shutdown_message}"

        # 执行关机操作
        /sbin/shutdown -h now
    fi

    # 删除一个月前的提醒文件
    find /var/tmp/ -name "reminder_sent_*" -mtime +25 -delete >/dev/null 2>&1
else
    echo "当前出站流量单位为 $tx_unit，不是 TiB，无需关机。"
fi
