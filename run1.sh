# py2.7环境下克隆 ShadowsocksR 仓库的 1 分支并且安装
cd ~
git clone https://github.com/110560/ShadowsocksR-py2.7.git shadowsocksr
cd shadowsocksr
apt-get install python-pip -y
pip install -r requestment.txt
