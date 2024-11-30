#!/bin/bash

# =======================
# 配置文件路径
# =======================
CONFIG_FILE="/etc/socat/socat_config.conf"

# =======================
# 脚本颜色定义
# =======================
Green="\033[32m"
Font_color_suffix="\033[0m"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Blue_font_prefix="\033[34m"

# =======================
# 确保以 root 用户运行
# =======================
rootness(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red_font_prefix}[ERROR] 本脚本必须以 root 用户执行！${Font_color_suffix}"
        exit 1
    fi
}

# =======================
# 检查系统类型
# =======================
checkos(){
    if [[ -f /etc/redhat-release ]]; then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian"; then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        OS=Ubuntu
    else
        echo -e "${Red_font_prefix}[ERROR] 不支持该操作系统，请重新安装操作系统！${Font_color_suffix}"
        exit 1
    fi
}

# =======================
# 安装 Socat
# =======================
install_socat(){
    echo -e "${Green}正在安装 Socat...${Font_color_suffix}"
    if [ "$OS" == "CentOS" ]; then
        yum install -y socat
    else
        apt-get update
        apt-get install -y socat
    fi
    if [ -s /usr/bin/socat ]; then
        echo -e "${Green}[INFO] Socat 安装成功！${Font_color_suffix}"
    else
        echo -e "${Red}[ERROR] Socat 安装失败！${Font_color_suffix}"
    fi
}

# =======================
# 创建配置文件夹
# =======================
create_config_dir(){
    if [ ! -d "/etc/socat" ]; then
        mkdir -p /etc/socat
    fi
}

# =======================
# 添加转发规则
# =======================
add_rule(){
    echo -e "${Green_font_prefix}请输入端口转发规则：${Font_color_suffix}"
    read -p "请输入本地端口: " bk_port
    read -p "请输入目标 IP: " ip
    read -p "请输入目标端口: " bk_port_pf

    # 将新规则写入配置文件
    echo "$bk_port $ip $bk_port_pf" >> $CONFIG_FILE
    echo -e "${Green}[INFO] 端口转发添加成功 [端口: ${bk_port} 被转发到 ${ip}:${bk_port_pf}]${Font_color_suffix}"

    # 自动启动 socat 转发
    start_socat

    # 提示用户是否继续添加配置
    read -e -p "是否继续添加端口转发配置？[Y/n]:" addyn
    if [[ "$addyn" =~ ^[Yy]$ ]]; then
        add_rule
    else
        main_menu
    fi
}

# =======================
# 启动 Socat 转发
# =======================
start_socat(){
    if [ -s /usr/bin/socat ]; then
        echo -e "${Green}正在启动 Socat 转发...${Font_color_suffix}"
        # 从配置文件加载规则
        while read -r line; do
            local port=$(echo $line | awk '{print $1}')
            local ip=$(echo $line | awk '{print $2}')
            local pf=$(echo $line | awk '{print $3}')
            # 启动 socat 进程
            nohup socat TCP4-LISTEN:$port,fork,reuseaddr TCP4:$ip:$pf &
            nohup socat UDP4-LISTEN:$port,fork,reuseaddr UDP4:$ip:$pf &
            echo -e "${Green}[INFO] Socat 转发已启动 [端口: ${port} 转发到 ${ip}:${pf}]${Font_color_suffix}"
        done < "$CONFIG_FILE"
    else
        echo -e "${Red}[ERROR] Socat 未安装，无法启动端口转发。${Font_color_suffix}"
    fi
}

# =======================
# 停止 Socat 转发
# =======================
stop_socat(){
    echo -e "${Red}正在停止 Socat 转发...${Font_color_suffix}"
    pkill -f "socat"
    echo -e "${Green}[INFO] Socat 转发已停止。${Font_color_suffix}"
}

# =======================
# 重启 Socat 转发
# =======================
restart_socat(){
    echo -e "${Green}正在重启 Socat 转发...${Font_color_suffix}"
    stop_socat
    sleep 1
    start_socat
}

# =======================
# 删除转发规则
# =======================
delete_rule(){
    echo -e "${Green_font_prefix}当前配置文件内容：${Font_color_suffix}"
    cat $CONFIG_FILE
    read -p "请输入要删除的本地端口: " del_port
    sed -i "/^$del_port /d" $CONFIG_FILE
    echo -e "${Green}[INFO] 端口转发删除成功 [端口: ${del_port}]${Font_color_suffix}"
}

# =======================
# 查看当前配置
# =======================
view_config(){
    echo -e "${Green_font_prefix}当前配置文件内容：${Font_color_suffix}"
    cat $CONFIG_FILE
}

# =======================
# 主菜单
# =======================
main_menu(){
    clear
    echo -e "${Green}1) 安装 Socat 并自动配置"
    echo "2) 卸载 Socat"
    echo "3) 查看当前配置"
    echo "4) 添加转发规则"
    echo "5) 删除转发规则"
    echo "6) 启动 Socat 转发"
    echo "7) 停止 Socat 转发"
    echo "8) 重启 Socat 转发"
    echo "9) 退出"
    echo -n "请输入选择操作: "
    read choice
    case $choice in
        1) install_socat;;
        2) uninstall_socat;;
        3) view_config;;
        4) add_rule;;
        5) delete_rule;;
        6) start_socat;;
        7) stop_socat;;
        8) restart_socat;;
        9) exit 0;;
        *) echo "无效选项，请重新选择." && main_menu;;
    esac
}

# =======================
# 卸载 Socat
# =======================
uninstall_socat(){
    if [ "$OS" == "CentOS" ]; then
        yum remove -y socat
    else
        apt-get remove --purge -y socat
    fi
    rm -f /etc/socat/socat_config.conf
    echo -e "${Green}[INFO] Socat 卸载成功！${Font_color_suffix}"
}

# =======================
# 脚本启动入口
# =======================
rootness
checkos
create_config_dir
main_menu
