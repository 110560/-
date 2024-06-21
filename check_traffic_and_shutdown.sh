#!/bin/bash

# 检查是否安装了 bc 工具
if ! command -v bc &> /dev/null; then
    echo "bc 工具未安装。请先安装 bc 工具。"
    exit 1
fi

# 获取当前月份的简称和年份
current_month=$(date +'%b '\''%y')

# 使用 vnstat 获取当前月份的出站流量
tx=$(vnstat -m | grep "$current_month" | awk '{print $6}')

# 检查是否成功获取到出站流量
if [[ -z "$tx" ]]; then
    echo "未能获取到当前月份的出站流量。"
else
    echo "当月出站流量：$tx"
fi

# 如果出站流量达到或超过1.97 TiB，则执行关机操作
threshold="1.97"
tx_value=$(echo $tx | sed 's/[^0-9.]//g')

if (( $(echo "$tx_value >= $threshold" | bc -l) )); then
    echo "出站流量达到或超过 $threshold TiB，系统即将关机。"
    sudo shutdown -h now
fi
