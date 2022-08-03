#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error：${plain} This script must be run as root user!\n" && exit 1

# install English
english(){
    bash <(curl -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-Install/en/install.sh)
}

# install Chinese
chinese(){
    bash <(curl -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-Install/zh/install.sh)
}

# install vietnamese
vietnamese(){
    bash <(curl -Ls https://raw.githubusercontent.com/AikoCute-Offical/AikoR-Install/vi/install.sh)
}   

show_menu() {
    echo -e "
  ${green}AikoR Các tập lệnh quản lý phụ trợ，${plain}${red}không hoạt động với docker${plain}
--- https://github.com/AikoCute-Offical/AikoR ---
  ${green}0.${plain} Exit Install AikoR
————————————————
  ${green}1.${plain} English
  ${green}2.${plain} 中文
  ${green}3.${plain} Vietnamese
 "
 # Cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "Please enter an option [0-3]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        *) echo -e "${red}Please enter the correct number [0-3]${plain}"
        ;;
    esac
}

show_menu
