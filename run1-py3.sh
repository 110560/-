#!/bin/bash

# 更新软件包列表和安装依赖项
apt update && apt install -y \
    libsqlite3-dev \
    libffi-dev \
    python3-pip \
    git \
    supervisor \
    vnstat \
    net-tools

# 克隆 ShadowsocksR 项目
git clone https://github.com/110560/shadowsocksr.git
cd shadowsocksr

# 安装 Python 依赖（注意：有 typo，修正为 requirement.txt）
pip install -r requirements.txt  --break-system-packages

# 配置 DNS
echo -e "options timeout:1 attempts:1 rotate\nnameserver 1.1.1.1\nnameserver 208.67.222.222" > /etc/resolv.conf

# 设置时区为上海
timedatectl set-timezone Asia/Shanghai

# 配置 Supervisor 管理 ShadowsocksR 服务
cat >> /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=python3 /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
EOF

# 增加文件描述符限制
echo "ulimit -n 102400" >> /etc/default/supervisor

# 重启 Supervisor 服务使配置生效
/etc/init.d/supervisor restart

# 添加定时任务，确保每天 6 点重启 ShadowsocksR
(crontab -l 2>/dev/null | grep -qFx "0 6 * * * supervisorctl restart ssr") || \
    (echo "0 6 * * * supervisorctl restart ssr" | crontab -)

# 结束脚本
echo "ShadowsocksR 服务已安装并配置成功，定时任务已添加。"
