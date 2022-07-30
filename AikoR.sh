#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 该脚本必须运行在root用户下!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}当前系统版本暂未支持, 请联系作者!${plain}\n" && exit 1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}请使用 CentOS 7 或更新版本!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更新版本!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更新版本!${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [y or n$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "是否确认重启 AikoR" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车键返回主菜单: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "输入指定版本（默认最新版本）: " && read version
    else
        version=$2
    fi
#    confirm "Chức năng này sẽ buộc cài đặt lại phiên bản mới nhất và dữ liệu sẽ không bị mất. Bạn có muốn tiếp tục không?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}Đã hủy${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/master/AikoR.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成，AikoR已自动重启，请查看AikoR日志${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "AikoR 配置修改后会自动重启"
    nano /etc/AikoR/aiko.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "AikoR 状态: ${green} 运行中 ${plain}"
            ;;
        1)
            echo -e "It is detected that you do not start AikoR or AikoR does not restart by itself, check the log？[Y/n]" && echo
            read -e -p "(yes or no):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "AikoR 状态: ${red} 未安装 ${plain}"
    esac
}

uninstall() {
    confirm "您确定要卸载 AikoR?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop AikoR
    systemctl disable AikoR
    rm /etc/systemd/system/AikoR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/AikoR/ -rf
    rm /usr/local/AikoR/ -rf
    rm /usr/bin/AikoR -f

    echo ""
    echo -e "${green}卸载成功，从系统中彻底卸载${plain}"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green} AikoR 已经启动了 ${plain}"
    else
        systemctl start AikoR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green} AikoR 启动成功 ${plain}"
        else
            echo -e "${red} AikoR 启动失败,  请检查 AikoR 日志${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop AikoR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green} AikoR 停止运行 ${plain}"
    else
        echo -e "${red} AikoR 停止失败, 可能是停止时间超过两秒，请检查日志查看原因 ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart AikoR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green} AikoR 重启成功, 请查看AikoR日志$ ${plain}"
    else
        echo -e "${red} AikoR 可能无法启动，请稍后使用AikoR Logs查看日志信息 ${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status AikoR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable AikoR
    if [[ $? == 0 ]]; then
        echo -e "${green} AikoR 设置自动启动成功 ${plain}"
    else
        echo -e "${red} AikoR 安装程序无法设置自动启动 ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable AikoR
    if [[ $? == 0 ]]; then
        echo -e "${green} AikoR 关闭自动启动 ${plain}"
    else
        echo -e "${red} AikoR 无法取消自动启动 ${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u AikoR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/AikoCute-Offical/Linux-BBR/aiko/tcp.sh)
}

update_shell() {
    wget -O /usr/bin/AikoR -N --no-check-certificate https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/master/AikoR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}脚本下载失败, 请检查服务器是否能连接到GitHub${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/AikoR
        echo -e "${green} 脚本更新成功, 请重新运行脚本 ${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/AikoR.service ]]; then
        return 2
    fi
    temp=$(systemctl status AikoR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled AikoR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red} AikoR 已经安装了, 无需重复安装 ${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red} 请先安装 AikoR ${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "AikoR 状态: ${green} 运行中 ${plain}"
            show_enable_status
            ;;
        1)
            echo -e "AikoR 状态: ${yellow} 没有运行 ${plain}"
            show_enable_status
            ;;
        2)
            echo -e "AikoR 状态: ${red} 未安装 ${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "自动启动: ${green} Yes ${plain}"
    else
        echo -e "自动启动: ${red} No ${plain}"
    fi
}

show_AikoR_version() {
    echo -n "AikoR 版本："
    /usr/local/AikoR/AikoR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo -e ""
    echo " How to use the AikoR . 管理脚本 " 
    echo "------------------------------------------"
    echo "           AikoR   - 显示主菜单      "
    echo "              AikoR by AikoCute           "
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}AikoR 后端管理脚本，${plain}${red} 不支持 docker${plain}
--- https://github.com/AikoCute-Offical/AikoR ---
  ${green}0.${plain} Setting Config
————————————————
  ${green}1.${plain} 安装 AikoR
  ${green}2.${plain} 更新 AikoR
  ${green}3.${plain} 卸载 AikoR
————————————————
  ${green}4.${plain} 启动 AikoR
  ${green}5.${plain} 停止 AikoR
  ${green}6.${plain} 重启 AikoR
  ${green}7.${plain} 显示 AikoR 状态
  ${green}8.${plain} 显示 AikoR 日志
————————————————
  ${green}9.${plain} 设置 AikoR 自启
 ${green}10.${plain} 取消 AikoR 自启
————————————————
 ${green}11.${plain} 安装 BBR
 ${green}12.${plain} 显示 AikoR 版本
 ${green}13.${plain} 更新 AikoR 脚本
 "
 # Cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "请选择 [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_AikoR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}请输入正确的号码 [0-13]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_AikoR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
