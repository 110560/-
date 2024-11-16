#!/bin/bash

# 检查Python版本
python_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [[ $python_version =~ ^2\. ]]; then
    echo "Python 2.x detected. Proceeding with installation."
else
    echo "This script requires Python 2.x to run ShadowsocksR. Aborting."
    exit 1
fi

# 更新软件包列表并安装必要的软件
apt-get update && apt-get install -y git python-pip supervisor vnstat net-tools

# 检查软件包安装是否成功
if [ $? -ne 0 ]; then
    echo "Failed to install necessary packages. Aborting."
    exit 1
fi

# 安装ShadowsocksR
cd ~
git clone https://github.com/110560/ShadowsocksR-py2.7.git shadowsocksr
if [ $? -ne 0 ]; then
    echo "Failed to clone ShadowsocksR repository. Aborting."
    exit 1
fi

cd shadowsocksr
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install dependencies. Aborting."
    exit 1
fi

# 配置DNS
echo -e "options timeout:1 attempts:1 rotate\nnameserver 1.1.1.1\nnameserver 208.67.222.222" >/etc/resolv.conf
# 设置时区
timedatectl set-timezone Asia/Shanghai

# 创建Supervisor配置文件
cat > /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=python /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
EOF

# 修改Supervisor默认配置
echo "ulimit -n 102400" >> /etc/default/supervisor

# 重启Supervisor并更新ShadowsocksR配置
/etc/init.d/supervisor restart
supervisorctl reread
supervisorctl update

# 添加定时任务，每天早上6点重启ShadowsocksR
(crontab -l 2>/dev/null | grep -qFx "0 6 * * * supervisorctl restart ssr") || (echo "0 6 * * * supervisorctl restart ssr" | crontab -)

# 结束脚本
echo "ShadowsocksR 服务已安装并配置成功，定时任务已添加。"
