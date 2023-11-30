#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用root用户运行此脚本！\n" && exit 1

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

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64-v8a"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="64"
    echo -e "${red}检测架构失败，使用默认架构: ${arch}${plain}"
fi

echo "架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "本软件不支持 32 位系统(x86)，请使用 64 位系统(x86_64)，如果检测有误，请联系作者"
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

install_acme() {
    curl https://get.acme.sh | sh
}

install_bunserver() {
    if [[ -e /usr/local/bunserver/ ]]; then
        rm /usr/local/bunserver/ -rf
    fi

    mkdir /usr/local/bunserver/ -p
	cd /usr/local/bunserver/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/pennyMorant/bunpanelServer/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}检测 bunserver 版本失败，可能是超出 Github API 限制，请稍后再试，或手动指定 bunserver 版本安装${plain}"
            exit 1
        fi
        echo -e "检测到 bunserver 最新版本：${last_version}，开始安装"
        wget -q -N --no-check-certificate -O /usr/local/bunserver/bunserver-linux.zip https://github.com/pennyMorant/bunpanelServer/releases/download/${last_version}/bunserver-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 bunserver 失败，请确保你的服务器能够下载 Github 的文件${plain}"
            exit 1
        fi
    else
        if [[ $1 == v* ]]; then
            last_version=$1
	else
	    last_version="v"$1
	fi
        url="https://github.com/pennyMorant/bunpanelServer/releases/download/${last_version}/bunserver-linux-${arch}.zip"
        echo -e "开始安装 bunserver ${last_version}"
        wget -q -N --no-check-certificate -O /usr/local/bunserver/bunserver-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}下载 bunserver ${last_version} 失败，请确保此版本存在${plain}"
            exit 1
        fi
    fi

    unzip bunserver-linux.zip
    rm bunserver-linux.zip -f
    chmod +x bunserver
    mkdir /etc/bunserver/ -p
    rm /etc/systemd/system/bunserver.service -f
    file="https://github.com/pennyMorant/bunpanel-release/raw/dev/server/bunserver.service"
    wget -q -N --no-check-certificate -O /etc/systemd/system/bunserver.service ${file}
    #cp -f bunserver.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop bunserver
    systemctl enable bunserver
    echo -e "${green}bunserver ${last_version}${plain} 安装完成，已设置开机自启"
    cp geoip.dat /etc/bunserver/
    cp geosite.dat /etc/bunserver/ 

    if [[ ! -f /etc/bunserver/config.yml ]]; then
        cp config.yml /etc/bunserver/
        echo -e ""
        echo -e "全新安装，请先参看教程：https://github.com/pennyMorant/bunpanelServer，配置必要的内容"
    else
        systemctl start bunserver
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "${green}bunserver 重启成功${plain}"
        else
            echo -e "${red}bunserver 可能启动失败，请稍后使用 bunserver log 查看日志信息，若无法启动，则可能更改了配置格式，请前往 wiki 查看：https://github.com/pennyMorant/bunpanelServer/wiki${plain}"
        fi
    fi

    if [[ ! -f /etc/bunserver/dns.json ]]; then
        cp dns.json /etc/bunserver/
    fi
    if [[ ! -f /etc/bunserver/route.json ]]; then
        cp route.json /etc/bunserver/
    fi
    if [[ ! -f /etc/bunserver/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/bunserver/
    fi
    if [[ ! -f /etc/bunserver/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/bunserver/
    fi
    if [[ ! -f /etc/bunserver/rulelist ]]; then
        cp rulelist /etc/bunserver/
    fi
    curl -o /usr/bin/bunserver -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/master/server/bunserver.sh
    chmod +x /usr/bin/bunserver
    cd $cur_dir
    rm -f install.sh
    echo -e ""
    echo "bunserver 管理脚本使用方法 (兼容使用bunserver执行，大小写不敏感): "
    echo "------------------------------------------"
    echo "bunserver                    - 显示管理菜单 (功能更多)"
    echo "bunserver start              - 启动 bunserver"
    echo "bunserver stop               - 停止 bunserver"
    echo "bunserver restart            - 重启 bunserver"
    echo "bunserver status             - 查看 bunserver 状态"
    echo "bunserver enable             - 设置 bunserver 开机自启"
    echo "bunserver disable            - 取消 bunserver 开机自启"
    echo "bunserver log                - 查看 bunserver 日志"
    echo "bunserver update             - 更新 bunserver"
    echo "bunserver update x.x.x       - 更新 bunserver 指定版本"
    echo "bunserver config             - 显示配置文件内容"
    echo "bunserver install            - 安装 bunserver"
    echo "bunserver uninstall          - 卸载 bunserver"
    echo "bunserver version            - 查看 bunserver 版本"
    echo "------------------------------------------"
}

echo -e "${green}开始安装${plain}"
install_base
# install_acme
install_bunserver $1
