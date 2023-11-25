# 安装教程
此教程基于1panel
服务端需要授权使用，如需测试请在此BOT申请测试授权码https://t.me/bunpanel_bot
# 环境
1. 进入1panel商店，安装openresty, postgersql
2. 准备三个域名，可以是三个子域名，分别对应用户前端，管理前端和服务端
# 安装用户前端
1. 创建网站，选择静态网站，域名填写准备的用户前端域名
2. 进入网站配置，然后编辑网站配置。在配置中输入： gzip_static on;
3. 进入网站根目录，然后进入index目录删除index.html
4. 上传前端源码到此目录，并解压
5. 打开config.json ，修改apiUrl: http://服务端域名(授权域名)
6. 现在应该可以访问前端页面了
# 安装管理前端
同上面步骤一样，不过域名是用准备的管理前端域名
# 安装服务端
### 进入服务器ssh，创建文件夹，并把服务端程序下载到此目录，并解压
    mkdir /var/www/bun
    cp .env.example .env
### 编辑 .env DB_USERNAME=数据库账户 DB_PASSWORD=数据库密码 APP_LICENSE=授权码
### 回到1panel,创建网站选择反向代理。这里域名填写准备好的服务端域名（授权域名），代理地址输入: 127.0.0.1:3000
### 回到ssh,进入目录 /var/www/bun, 然后执行 ./bunpanel-x64
### 然后就可以看到输出的日志，红色部分为管理员账号和密码
# 守护进程
    [program:bunpanel]
    directory=/var/www/bun
    command=/var/www/bun/bunpanel-x64
    user=root
    autostart=true
    autorestart=true
    numprocs=1
    redirect_stderr=true
    stdout_logfile=/var/log/supervisor/bunpanel.log
### 复制上面的代码然后执行代码
    vim /etc/supervisor/conf.d/bun.conf
### 把复制的代粘贴进去，保存退出.然后执行
    supervisorctl reread
    supervisorctl update
    supervisorctl start bunpanel
