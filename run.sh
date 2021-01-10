#!/bin/bash

# 安装软件
apt-get update
apt-get install -y git supervisor vnstat
apt-get install net-tools -y


# 配置dns
echo -e "options timeout:1 attempts:1 rotate\nnameserver 8.8.8.8\nnameserver 8.8.4.4" >/etc/resolv.conf

# 切换时区
timedatectl set-timezone Asia/Shanghai



cd ~
git clone https://github.com/ZBrettonYe/ProxyPanel_shadowsocksr.git
mv ProxyPanel_shadowsocksr shadowsocksr 
cd shadowsocksr
apt-get install python-pip -y
pip install -r requestment.txt


cat  >> /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=python /root/shadowsocksr/server.py 
autorestart=true
autostart=true
user=root
EOF


echo "ulimit -n 102400" >> /etc/default/supervisor
/etc/init.d/supervisor restart
supervisorctl restart ssr

vnstat -u -i eth0

systemctl vnstat start

chown -R vnstat:vnstat /var/lib/vnstat

/etc/init.d/vnstat restart
