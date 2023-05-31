apt-get install -y supervisor vnstat
apt-get install net-tools -y
echo -e "options timeout:1 attempts:1 rotate\nnameserver 8.8.8.8\nnameserver 8.8.4.4" >/etc/resolv.conf
timedatectl set-timezone Asia/Shanghai
echo "0 6 * * * supervisorctl restart ssr" >> /var/spool/cron/crontabs/root

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
