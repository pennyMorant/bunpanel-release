#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

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
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n" && exit 1
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
        echo -e "${red}请使用 CentOS 7 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更高版本的系统！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更高版本的系统！${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
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
    confirm "是否重启bunserver" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/install.sh)
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
        echo && echo -n -e "输入指定版本(默认最新版): " && read version
    else
        version=$2
    fi
#    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" "n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}已取消${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}更新完成，已自动重启 bunserver，请使用 bunserver log 查看运行日志${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "bunserver在修改配置后会自动尝试重启"
    vi /etc/bunserver/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "bunserver状态: ${green}已运行${plain}"
            ;;
        1)
            echo -e "检测到您未启动bunserver或bunserver自动重启失败，是否查看日志？[Y/n]" && echo
            read -e -p "(默认: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "bunserver状态: ${red}未安装${plain}"
    esac
}

uninstall() {
    confirm "确定要卸载 bunserver 吗?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop bunserver
    systemctl disable bunserver
    rm /etc/systemd/system/bunserver.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/bunserver/ -rf
    rm /usr/local/bunserver/ -rf

    echo ""
    echo -e "卸载成功，如果你想删除此脚本，则退出脚本后运行 ${green}rm /usr/bin/bunserver -f${plain} 进行删除"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}bunserver已运行，无需再次启动，如需重启请选择重启${plain}"
    else
        systemctl start bunserver
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}bunserver 启动成功，请使用 bunserver log 查看运行日志${plain}"
        else
            echo -e "${red}bunserver可能启动失败，请稍后使用 bunserver log 查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    systemctl stop bunserver
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}bunserver 停止成功${plain}"
    else
        echo -e "${red}bunserver停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart bunserver
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}bunserver 重启成功，请使用 bunserver log 查看运行日志${plain}"
    else
        echo -e "${red}bunserver可能启动失败，请稍后使用 bunserver log 查看日志信息${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status bunserver --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable bunserver
    if [[ $? == 0 ]]; then
        echo -e "${green}bunserver 设置开机自启成功${plain}"
    else
        echo -e "${red}bunserver 设置开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable bunserver
    if [[ $? == 0 ]]; then
        echo -e "${green}bunserver 取消开机自启成功${plain}"
    else
        echo -e "${red}bunserver 取消开机自启失败${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u bunserver.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}安装 bbr 成功，请重启服务器${plain}"
    #else
    #    echo ""
    #    echo -e "${red}下载 bbr 安装脚本失败，请检查本机能否连接 Github${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/bunserver -N --no-check-certificate https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/bunserver.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}下载脚本失败，请检查本机能否连接 Github${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/bunserver
        echo -e "${green}升级脚本成功，请重新运行脚本${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /etc/systemd/system/bunserver.service ]]; then
        return 2
    fi
    temp=$(systemctl status bunserver | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled bunserver)
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
        echo -e "${red}bunserver已安装，请不要重复安装${plain}"
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
        echo -e "${red}请先安装bunserver${plain}"
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
            echo -e "bunserver状态: ${green}已运行${plain}"
            show_enable_status
            ;;
        1)
            echo -e "bunserver状态: ${yellow}未运行${plain}"
            show_enable_status
            ;;
        2)
            echo -e "bunserver状态: ${red}未安装${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "是否开机自启: ${green}是${plain}"
    else
        echo -e "是否开机自启: ${red}否${plain}"
    fi
}

show_bunserver_version() {
    echo -n "bunserver 版本："
    /usr/local/bunserver/bunserver -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo "bunserver 管理脚本使用方法: "
    echo "------------------------------------------"
    echo "bunserver              - 显示管理菜单 (功能更多)"
    echo "bunserver start        - 启动 bunserver"
    echo "bunserver stop         - 停止 bunserver"
    echo "bunserver restart      - 重启 bunserver"
    echo "bunserver status       - 查看 bunserver 状态"
    echo "bunserver enable       - 设置 bunserver 开机自启"
    echo "bunserver disable      - 取消 bunserver 开机自启"
    echo "bunserver log          - 查看 bunserver 日志"
    echo "bunserver update       - 更新 bunserver"
    echo "bunserver update x.x.x - 更新 bunserver 指定版本"
    echo "bunserver install      - 安装 bunserver"
    echo "bunserver uninstall    - 卸载 bunserver"
    echo "bunserver version      - 查看 bunserver 版本"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
  ${green}bunserver 后端管理脚本，${plain}${red}不适用于docker${plain}
--- https://github.com/zeropanel/bunserver ---
  ${green}0.${plain} 修改配置
————————————————
  ${green}1.${plain} 安装 bunserver
  ${green}2.${plain} 更新 bunserver
  ${green}3.${plain} 卸载 bunserver
————————————————
  ${green}4.${plain} 启动 bunserver
  ${green}5.${plain} 停止 bunserver
  ${green}6.${plain} 重启 bunserver
  ${green}7.${plain} 查看 bunserver 状态
  ${green}8.${plain} 查看 bunserver 日志
————————————————
  ${green}9.${plain} 设置 bunserver 开机自启
 ${green}10.${plain} 取消 bunserver 开机自启
————————————————
 ${green}11.${plain} 一键安装 bbr (最新内核)
 ${green}12.${plain} 查看 bunserver 版本 
 ${green}13.${plain} 升级维护脚本
 "
 #后续更新可加入上方字符串中
    show_status
    echo && read -p "请输入选择 [0-13]: " num

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
        12) check_install && show_bunserver_version
        ;;
        13) update_shell
        ;;
        *) echo -e "${red}请输入正确的数字 [0-12]${plain}"
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
        "version") check_install 0 && show_bunserver_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
