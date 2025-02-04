#!/bin/bash

set -e  # 遇到错误立即退出

# 检查 Python 版本是否为 2.x
if ! command -v python2 &>/dev/null; then
    echo "Python 2 is not installed. Please install Python 2.x before running this script."
    exit 1
fi

python_version=$(python2 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ $python_version =~ ^2\. ]]; then
    echo "Python 2.x detected. Proceeding with installation."
else
    echo "This script requires Python 2.x to run ShadowsocksR. Aborting."
    exit 1
fi

# 检查并安装 Supervisor
if ! command -v supervisorctl &>/dev/null; then
    echo "Supervisor is not installed. Installing..."
    apt-get update && apt-get install -y supervisor
    if [ $? -ne 0 ]; then
        echo "Failed to install Supervisor. Aborting."
        exit 1
    fi
    echo "Supervisor installed successfully."
else
    echo "Supervisor is already installed. Proceeding..."
fi

# 确保 Supervisor 服务正在运行
systemctl enable supervisor
systemctl start supervisor || { echo "Failed to start Supervisor. Aborting."; exit 1; }

# 安装 ShadowsocksR
cd ~
if [ ! -d "shadowsocksr" ]; then
    git clone https://github.com/110560/ShadowsocksR-py2.7.git shadowsocksr
    if [ $? -ne 0 ]; then
        echo "Failed to clone ShadowsocksR repository. Aborting."
        exit 1
    fi
else
    echo "ShadowsocksR repository already exists. Skipping clone."
fi

cd shadowsocksr

# 安装 pip 和依赖
if ! command -v pip &>/dev/null; then
    apt-get install -y python-pip
fi

pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install dependencies. Aborting."
    exit 1
fi

# 覆盖 DNS 配置
echo -e "options timeout:1 attempts:1 rotate\nnameserver 1.1.1.1\nnameserver 208.67.222.222" > /etc/resolv.conf
echo "DNS configuration overwritten."

# 检查并创建 Supervisor 配置文件
ssr_config="/etc/supervisor/conf.d/ssr.conf"
if [ ! -f "$ssr_config" ]; then
    cat > "$ssr_config" <<EOF
[program:ssr]
command=python2 /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
EOF
    echo "Supervisor configuration file created."
else
    echo "Supervisor configuration file already exists. Skipping creation."
fi

# 修改 Supervisor 配置，确保 ulimit 限制生效
supervisor_conf="/etc/supervisor/supervisord.conf"
if ! grep -q "ulimit -n 102400" "$supervisor_conf"; then
    echo "
[supervisord]
minfds=102400
" >> "$supervisor_conf"
    echo "Updated Supervisor ulimit configuration."
else
    echo "Supervisor ulimit configuration already set. Skipping."
fi

# 重新加载 Supervisor 配置
systemctl restart supervisor
supervisorctl reread
supervisorctl update

# 添加定时任务，每天早上 6 点重启 ShadowsocksR
cron_job="0 6 * * * supervisorctl restart ssr"
(crontab -l 2>/dev/null | grep -qFx "$cron_job") || (echo "$cron_job" | crontab -)

# 结束脚本
echo "ShadowsocksR 服务已安装并配置成功，Supervisor 也已检查/安装，DNS 已覆盖，定时任务已添加。"
