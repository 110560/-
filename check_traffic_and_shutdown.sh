#!/bin/bash
#兼容vnStat 1.18 2.6
# 检查是否安装了 bc 工具
if ! command -v bc &> /dev/null; then
    echo "bc 工具未安装。请先安装 bc 工具。"
    exit 1
fi

# 获取当前月份和年份
current_month_v2=$(date +'%Y-%m')
current_month_v1=$(date +'%b '\''%y')

# 提醒文件路径
reminder_file="/var/tmp/reminder_sent_$current_month_v1"

# 获取外网 IP
external_ip=$(curl -s ifconfig.me)

# 获取当前日期和时间
current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

# Telegram Bot API Token
bot_token="5162966701:AAGFVyYWQ45A_eaSYi4XlVYDvHzZ6frSmXQ"
# Chat ID
chat_id="461449457"

# 使用 vnstat 获取当前月份的出站流量
tx_v1=$(vnstat -m | grep "$current_month_v1" | awk '{print $6, $7}')
tx_v2=$(vnstat -m | grep "$current_month_v2" | awk '{print $4, $5}')

# 检查并选择有效的出站流量
if [[ -n "$tx_v2" ]]; then
    tx="$tx_v2"
    current_month="$current_month_v2"
elif [[ -n "$tx_v1" ]]; then
    tx="$tx_v1"
    current_month="$current_month_v1"
else
    echo "未能获取到当前月份的出站流量。"
    exit 1
fi

# 解析出站流量的数值和单位
tx_value=$(echo "$tx" | awk '{print $1}')
tx_unit=$(echo "$tx" | awk '{print $2}')

# 默认单位为 GiB
if [[ -z "$tx_unit" ]]; then
    tx_unit="GiB"
fi

# 将 GiB 转换为 TiB
if [[ "$tx_unit" == "GiB" ]]; then
    tx_value=$(echo "scale=2; $tx_value / 1024" | bc | awk '{printf "%.2f", $0}')
    tx_unit="TiB"
fi

# 检查单位是否为 TiB
if [[ "$tx_unit" == "TiB" ]]; then
    threshold="1.90"
    shutdown_threshold="1.97"

    # 检查是否达到提醒阈值 1.90 TiB
    if (( $(echo "$tx_value >= $threshold" | bc -l) )) && [[ ! -f "$reminder_file" ]]; then
        # 发送提醒消息到 Telegram
        message="出站流量已达到 $threshold TiB。外网 IP: $external_ip 时间: $current_datetime"
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
             -d chat_id="${chat_id}" \
             -d text="${message}"

        echo "出站流量达到或超过 $threshold TiB，提醒消息已发送。"

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

        echo "出站流量达到或超过 $shutdown_threshold TiB，系统即将关机提醒已发送。"
        echo "出站流量达到或超过 $shutdown_threshold TiB，系统即将关机。"
        # 执行关机操作
        shutdown -h now
    else
        echo "当前出站流量为 $tx_value TiB，未达到关机阈值 $shutdown_threshold TiB。"
    fi

    # 删除一个月前的提醒文件
    find /var/tmp/ -name "reminder_sent_*" -mtime +25 -delete >/dev/null 2>&1
else
    echo "当前出站流量单位为 $tx_unit，不是 TiB，无需关机。"
fi
