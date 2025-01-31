# py2.7环境下克隆 ShadowsocksR 仓库的 1 分支并且安装
cd ~
git clone -b 1 https://github.com/110560/shadowsocksr.git
cd shadowsocksr
apt-get install python-pip -y
pip install -r requestment.txt
