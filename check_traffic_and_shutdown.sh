#!/bin/bash

# 检查是否安装了 bc 工具
if ! command -v bc &> /dev/null; then
    echo "bc 工具未安装。请先安装 bc 工具。"
    exit 1
fi

# 获取当前月份的简称和年份
current_month=$(date +'%b '\''%y')

# 使用 vnstat 获取当前月份的出站流量
tx=$(vnstat -m | grep "$current_month" | awk '{print $6, $7}')

# 检查是否成功获取到出站流量
if [[ -z "$tx" ]]; then
    echo "未能获取到当前月份的出站流量。"
    exit 1
else
    echo "当月出站流量：$tx"
fi

# 解析出站流量的数值和单位
tx_value=$(echo $tx | awk '{print $1}')
tx_unit=$(echo $tx | awk '{print $2}')

# 默认单位为 GiB
if [[ -z "$tx_unit" ]]; then
    tx_unit="GiB"
fi

# 输出调试信息
echo "调试信息："
echo "tx: $tx"
echo "tx_value: $tx_value"
echo "tx_unit: $tx_unit"

# 将 GiB 转换为 TiB
if [[ "$tx_unit" == "GiB" ]]; then
    tx_value=$(echo "scale=2; $tx_value / 1024" | bc | awk '{printf "%.2f", $0}')
    tx_unit="TiB"
fi

# 检查单位是否为 TiB
if [[ "$tx_unit" == "TiB" ]]; then
    threshold="1.90"
    shutdown_threshold="1.97"
    reminder_file="/var/tmp/reminder_sent_$current_month"
    
    # 检查是否达到提醒阈值 1.90 TiB
    if (( $(echo "$tx_value >= $threshold" | bc -l) )); then
        if [[ ! -f "$reminder_file" ]]; then
            # 获取外网 IP
            external_ip=$(curl -s ifconfig.me)

            # 获取当前日期和时间
            current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

            # Telegram Bot API Token
            bot_token="5162966701:AAGFVyYWQ45A_eaSYi4XlVYDvHzZ6frSmXQ"  # 替换为实际的 Bot Token
            # Chat ID
            chat_id="461449457"  # 替换为实际的 Chat ID

            # 消息内容
            message="出站流量已达到 $threshold TiB。外网 IP: $external_ip 时间: $current_datetime"

            # 发送消息到 Telegram
            curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
                 -d chat_id="${chat_id}" \
                 -d text="${message}"

            echo "出站流量达到或超过 $threshold TiB，提醒消息已发送。"

            # 创建提醒文件
            touch "$reminder_file"
        fi
    fi

    # 检查是否达到关机阈值 1.97 TiB
    if (( $(echo "$tx_value >= $shutdown_threshold" | bc -l) )); then
        # 获取外网 IP
        external_ip=$(curl -s ifconfig.me)

        # 获取当前日期和时间
        current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

        # 发送关机提醒消息到 Telegram
        shutdown_message="服务器即将关机！出站流量已达到 $shutdown_threshold TiB。外网 IP: $external_ip 时间: $current_datetime"
        curl -s -X POST "https://api.telegram.org/bot${bot_token}/sendMessage" \
             -d chat_id="${chat_id}" \
             -d text="${shutdown_message}"

        echo "出站流量达到或超过 $shutdown_threshold TiB，系统即将关机提醒已发送。"
        echo "出站流量达到或超过 $shutdown_threshold TiB，系统即将关机。"
        sudo shutdown -h now
    else
        echo "当前出站流量为 $tx_value TiB，未达到关机阈值 $shutdown_threshold TiB。"
    fi

    # 删除一个月前的提醒文件
    find /var/tmp/ -name "reminder_sent_*" -mtime +25 -delete >/dev/null 2>&1
else
    echo "当前出站流量单位为 $tx_unit，不是 TiB，无需关机。"
fi
