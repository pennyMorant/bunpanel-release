#!/bin/bash

get_linux_distribution_and_cpu() {
    # 检查是否存在 /etc/os-release 文件
    if [ -f /etc/os-release ]; then
        # 导入文件以获取发行版信息
        source /etc/os-release
        if [ -n "$ID" ]; then
            DISTRIBUTION="$ID"
        else
            echo "无法检测到Linux发行版本。"
            exit 1
        fi
    else
        echo "无法检测到Linux发行版本。"
        exit 1
    fi

    # 检查CPU是否支持64位
    if [ "$(lscpu | grep "Architecture" | awk '{print $2}')" != "x86_64" ]; then
        echo "CPU不支持64位操作系统。"
        exit 1
    fi
}

install_packages() {
    case "$DISTRIBUTION" in
        "ubuntu" | "debian")
            apt-get update
            apt-get install -y zip curl postgresql supervisor
            ;;

        "centos" | "rhel")
            yum install -y zip curl postgresql supervisor
            ;;
        *)
            echo "不支持的Linux发行版本: $DISTRIBUTION"
            exit 1
            ;;
    esac
}

download_latest_release() {
    API_URL="https://api.github.com/repos/zeropanel/bunpanel-release/releases/latest"
    TAG=$(curl -s $API_URL | grep -o '"tag_name": ".*"' | cut -d '"' -f 4)
    echo "版本：$TAG"
    ARCHITECTURE="$(uname -m)"  # 获取系统架构
    case "$ARCHITECTURE" in
        "x86_64")
            RELEASE_FILE="bunpanel-x64.zip"
            ;;
        "aarch64")
            RELEASE_FILE="bunpanel-arm64.zip"
            ;;
        *)
            echo "不支持的系统架构: $ARCHITECTURE"
            exit 1
            ;;
    
    esac
    REPO_URL="https://github.com/zeropanel/bunpanel-release/releases/download/$TAG/$RELEASE_FILE"
    RELEASE_URL=$(curl -sI -o /dev/null -w %{url_effective} "$REPO_URL")

    if [ -z "$RELEASE_URL" ]; then
        echo "无法获取最新发布版本的URL。"
        exit 1
    fi

    echo "正在下载最新发布版本：$RELEASE_FILE"
    wget "$RELEASE_URL"

    if [ $? -ne 0 ]; then
        echo "下载失败：$RELEASE_URL"
        exit 1
    fi
}

extract_zip_file() {
    ZIP_FILE="$RELEASE_FILE"
    DEST_DIR="/var/www/bun"

    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR"
    fi

    unzip -q "$ZIP_FILE" -d "$DEST_DIR"
    rm "$ZIP_FILE"
    if [ $? -ne 0 ]; then
        echo "解压失败：$ZIP_FILE"
        exit 1
    fi
}


create_supervisor_config() {
    supervisor_config="/etc/supervisor/conf.d/bun.conf"
    bunpanel_command="bunpanel-x64"  # 默认使用x64配置文件

    # 检测系统架构，如果为arm64，则使用arm64配置文件
    if [ "$(uname -m)" == "aarch64" ]; then
        bunpanel_command="bunpanel-arm64"
    fi

    cat > "$supervisor_config" <<EOL
[program:bunpanel]
directory=/var/www/bun
command=/var/www/bun/$bunpanel_command
user=root
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/supervisor/bunpanel.log
EOL

    echo "Supervisor配置文件已创建：$supervisor_config"
}

create_db() {
    read -p "请输入数据库名称：" DB_NAME
    read -p "请输入数据库用户名：" DB_USER
    read -p "请输入数据库密码：" DB_PASSWORD
    echo

    psql -U postgres -c "CREATE DATABASE $DB_NAME;"
    psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
    psql -U postgres -c "ALTER USER $DB_USER WITH SUPERUSER;"
    echo "数据库和用户创建成功，并已授予全部权限。"
}


start_app() {
    read -p "请输入授权码: " LICENSE_KEY
    echo

    ENV_FILE="/var/www/bun/.env"
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" "$ENV_FILE"
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" "$ENV_FILE"
    sed -i "s/APP_LICENSE=.*/LICENSE_KEY=$LICENSE_KEY/" "$ENV_FILE"
    supervisorctl reread
    supervisorctl update
    supervisorctl start bunpanel
    echo "waiting 5s"
    sleep 5
    cat /var/log/supervisor/bunpanel.log
    echo "程序启动成功, 红色内容部分为管理员账户和密码"
}




# 主程序
get_linux_distribution_and_cpu
install_packages
download_latest_release
extract_zip_file
create_supervisor_config
start_app
echo "安装完成！"
