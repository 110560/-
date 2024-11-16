#!/bin/bash

# 检查Python版本
python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ $python_version =~ ^3\. ]]; then
    echo "Python 3.x detected. Proceeding with installation."
else
    echo "This script requires Python 3.x to run ShadowsocksR. Aborting."
    exit 1
fi

# 更新软件包列表和安装依赖项
if ! apt update || ! apt install -y \
    libsqlite3-dev \
    libffi-dev \
    python3-pip \
    git \
    supervisor \
    vnstat \
    net-tools; then
    echo "Failed to update package list or install necessary packages. Aborting."
    exit 1
fi

# 克隆 ShadowsocksR 项目
if [ ! -d ~/shadowsocksr ]; then
    git clone https://github.com/110560/shadowsocksr.git ~/shadowsocksr
    if [ $? -ne 0 ]; then
        echo "Failed to clone ShadowsocksR repository. Aborting."
        exit 1
    fi
else
    echo "ShadowsocksR repository already exists. Skipping cloning."
fi

cd ~/shadowsocksr

# 安装 Python 依赖
if ! pip install -r requirements.txt --break-system-packages; then
    echo "Failed to install dependencies. Aborting."
    exit 1
fi

# 配置 DNS
if ! grep -q "nameserver 1.1.1.1" /etc/resolv.conf; then
    echo -e "options timeout:1 attempts:1 rotate\nnameserver 1.1.1.1\nnameserver 208.67.222.222" > /etc/resolv.conf
    echo "DNS configuration updated."
else
    echo "DNS configuration already exists. Skipping."
fi

# 设置时区为上海
if ! timedatectl set-timezone Asia/Shanghai; then
    echo "Failed to set timezone. Aborting."
    exit 1
fi

# 配置 Supervisor 管理 ShadowsocksR 服务
if [ ! -f /etc/supervisor/conf.d/ssr.conf ]; then
    cat > /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=python3 /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
EOF
    echo "Supervisor configuration file created."
else
    echo "Supervisor configuration file already exists. Skipping creation."
fi

# 增加文件描述符限制
if ! grep -q "ulimit -n 102400" /etc/default/supervisor; then
    echo "ulimit -n 102400" >> /etc/default/supervisor
    echo "Modified Supervisor default configuration."
else
    echo "Supervisor default configuration already modified. Skipping."
fi

# 重启 Supervisor 服务使配置生效
if ! /etc/init.d/supervisor restart; then
    echo "Failed to restart Supervisor service. Aborting."
    exit 1
fi

# 添加定时任务，确保每天 6 点重启 ShadowsocksR
(crontab -l 2>/dev/null | grep -qFx "0 6 * * * supervisorctl restart ssr") || \
    (echo "0 6 * * * supervisorctl restart ssr" | crontab -)

# 结束脚本
echo "ShadowsocksR 服务已安装并配置成功，定时任务已添加。"
