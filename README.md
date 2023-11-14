# 安装教程
此教程基于1panel
服务端需要授权使用，如需测试请在此BOT申请测试授权码https://t.me/bunpanel_bot
# 环境
1. 进入1panel商店，安装openresty, postgersql
2. 准备三个域名，可以是三个子域名，分别对应用户前端，管理前端和服务端
# 安装用户前端
1. 创建网站，选择静态网站，域名填写准备的用户前端域名
2. 进入网站根目录，然后进入index目录删除index.html
3. 上传前端源码到此目录，并解压
4. 打开config.json ，修改apiUrl: http://服务端域名(授权域名)
5. 现在应该可以访问前端页面了
# 安装管理前端
同上面步骤一样，不过域名是用准备的管理前端域名
# 安装服务端
1. 进入服务器ssh，创建文件夹，并把服务端程序下载到此目录，并解压
        mkdir /var/www/bun
2. cp .env.example .env
3. 编辑 .env DB_USERNAME=数据库账户 DB_PASSWORD=数据库密码 APP_LICENSE=授权码 TRUST_PROXY=true
4. 回到1panel,创建网站选择反向代理。这里域名填写准备好的服务端域名（授权域名），代理地址输入: 127.0.0.1:3000
5. 回到ssh,进入目录 /var/www/bun, 然后执行 ./bunpanel-x64
6. 然后就可以看到输出的日志，红色部分为管理员账号和密码
7. 如需进程守护，请使用1panel的supervisor管理进程守护即可
