# Py2.7下 dns 修改 守护进程

echo -e "options timeout:1 attempts:1 rotate\nnameserver 1.1.1.1\nnameserver 208.67.222.222" >/etc/resolv.conf

cat >> /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=python /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
EOF

echo "ulimit -n 102400" >> /etc/default/supervisor
/etc/init.d/supervisor restart
supervisorctl restart ssr

(crontab -l 2>/dev/null | grep -qFx "0 6 * * * supervisorctl restart ssr") || (echo "0 6 * * * supervisorctl restart ssr" | crontab -)
