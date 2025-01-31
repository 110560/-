#!/bin/bash

# 这是一个安装并配置 ShadowsocksR 代理服务的脚本。
# 脚本执行以下操作：
# 1. 配置 Debian 源
# 2. 克隆 ShadowsocksR 源代码
# 3. 安装编译依赖
# 4. 安装 pyenv 和 Python 3.7.1
# 5. 配置 Supervisor 管理 ShadowsocksR
# 6. 设置每日定时重启 ShadowsocksR 服务

# 配置 Debian 软件源
echo -e "# 官方主镜像源\ndeb http://deb.debian.org/debian/ bookworm main contrib non-free\ndeb-src http://deb.debian.org/debian/ bookworm main contrib non-free\n\n# 官方更新镜像源\ndeb http://deb.debian.org/debian/ bookworm-updates main contrib non-free\ndeb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free\n\n# 官方安全更新镜像源\ndeb http://security.debian.org/debian-security bookworm-security main contrib non-free\ndeb-src http://security.debian.org/debian-security bookworm-security main contrib non-free" | sudo tee /etc/apt/sources.list

# 克隆 ShadowsocksR 仓库
git clone -b 1 https://github.com/110560/shadowsocksr.git

# 安装编译所需的依赖包
sudo apt-get update && sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev gcc libssl-dev libreadline-dev libsqlite3-dev \
bzip2 libbz2-dev

# 安装 pyenv
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash

# 配置 pyenv 环境变量
cat >> ~/.bashrc << EOF
export PATH="/root/.pyenv/bin:\$PATH"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"
EOF
source ~/.bashrc

# 安装 Python 3.7.1
pyenv install 3.7.1
pyenv global 3.7.1

# 进入 ShadowsocksR 目录并安装 Python 依赖
cd shadowsocksr
pip install -r requestment.txt

# 配置 Supervisor 以自动管理 ShadowsocksR 服务
cd /root
cat >> /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
command=pyenv exec python /root/shadowsocksr/server.py
autorestart=true
autostart=true
user=root
environment=PATH="/root/.pyenv/shims:/root/.pyenv/bin:/root/.pyenv/plugins/pyenv-virtualenv/shims:/root/.pyenv/shims:/root/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",PYENV_ROOT="/root/.pyenv"
EOF

# 修改文件描述，增加文件描述限制
echo "ulimit -n 102400" >> /etc/default/supervisor

# 重启 Supervisor 服务
/etc/init.d/supervisor restart

# 重启 ShadowsocksR 服务
supervisorctl restart ssr

# 设置定时任务，确保每天 6 点重启 ShadowsocksR
(crontab -l 2>/dev/null | grep -qFx "0 6 * * * supervisorctl restart ssr") || (echo "0 6 * * * supervisorctl restart ssr" | crontab -)
