#!/bin/bash

# 安装软件
apt-get update
apt-get install -y git supervisor vnstat
apt-get install net-tools -y
wget https://cdn.ipip.net/17mon/besttrace4linux.zip

# 路由跟踪
unzip besttrace4linux.zip
chmod +x besttrace

# 配置dns
echo -e "options timeout:1 attempts:1 rotate\nnameserver 8.8.8.8\nnameserver 8.8.4.4" >/etc/resolv.conf

# 切换时区
timedatectl set-timezone Asia/Shanghai


cd ~
git clone https://github.com/LEE-Blog/shadowsocksr.git
cd shadowsocksr
sh setup_cymysql2.sh
sh initcfg.sh


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
