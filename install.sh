#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 该脚本必须运行在root用户下!\n" && exit 1

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

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "${red}当前架构暂未支持, 使用默认架构: ${arch}${plain}"
fi

echo "系统架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "当前暂未支持 32-bit (x86) 系统, 请使用 64-bit (x86_64) 系统, 如果识别错误, 请联系作者"
    exit 2
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

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
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

install_acme() {
    curl https://get.acme.sh | sh
}

install_AikoR() {
    if [[ -e /usr/local/AikoR/ ]]; then
        rm /usr/local/AikoR/ -rf
    fi

    mkdir /usr/local/AikoR/ -p
	cd /usr/local/AikoR/
    
    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/AikoCute-Offical/AikoR/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red} AikoR 版本检测失败, 可能是 GitHub API超限, 请稍后再试或手动指定 AikoR 版本设置${plain}"
            exit 1
        fi
        echo -e "检测到最新AikoR版本：${last_version}，开始安装"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR-linux.zip https://github.com/AikoCute-Offical/AikoR/releases/download/${last_version}/AikoR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}AikoR 下载失败, 请确认您的服务器可以链接到GitHub${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/AikoCute-Offical/AikoR/releases/download/${last_version}/AikoR-linux-${arch}.zip"
        echo -e "开始安装 AikoR v$1"
        wget -N --no-check-certificate -O /usr/local/AikoR/AikoR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 AikoR v$1 失败, 请确认该版本是否存在${plain}"
            exit 1
        fi
    fi

    unzip AikoR-linux.zip
    rm AikoR-linux.zip -f
    chmod +x AikoR
    mkdir /etc/AikoR/ -p
    rm /etc/systemd/system/AikoR.service -f
    file="https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/zh/AikoR.service"
    wget -N --no-check-certificate -O /etc/systemd/system/AikoR.service ${file}
    #cp -f AikoR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop AikoR
    systemctl enable AikoR
    echo -e "${green}AikoR ${last_version}${plain} 安装完成, 并已设为自动启动"
    cp geoip.dat /etc/AikoR/
    cp geosite.dat /etc/AikoR/ 

    if [[ ! -f /etc/AikoR/aiko.json ]]; then
        cp aiko.json /etc/AikoR/
        echo -e ""
        echo -e "全新安装, 请参考之前的教程：https://github.com/AikoCute-Offical/AikoR，配置所需内容"
    else
        systemctl start AikoR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}AikoR 重启完成${plain}"
        else
            echo -e "${red}AikoR 可能并未启动, 请查看AikoR日志, 如果启动失败，可能是配置格式改变了, 请到wiki查看：https://github.com/AikoCute-Offical/AikoR${plain}"
        fi
    fi

    if [[ ! -f /etc/AikoR/dns.json ]]; then
        cp dns.json /etc/AikoR/
    fi
    if [[ ! -f /etc/AikoR/route.json ]]; then
        cp route.json /etc/AikoR/
    fi
    if [[ ! -f /etc/AikoR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/AikoR/
    fi
    curl -o /usr/bin/AikoR -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-install/zh/AikoR.sh
    chmod +x /usr/bin/AikoR
    ln -s /usr/bin/AikoR /usr/bin/aikor # compatible lowercase
    chmod +x /usr/bin/aikor

    echo -e ""
    echo " How to use the AikoR . 管理脚本 " 
    echo "------------------------------------------"
    echo "           AikoR   - 显示管理员菜单      "
    echo "               AikoR by AikoCute          "
    echo "------------------------------------------"
}

echo -e "${green}全新安装${plain}"
install_base
install_acme
install_AikoR $1