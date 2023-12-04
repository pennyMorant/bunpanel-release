# 安装教程 | [Demo](https://demo.bunpanel.com) | [Telegram](https://t.me/bunpanel)
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
1. 创建网站，选择反向代理
2. 进入网站根目录，然后进入index目录。把服务端代码上传到此目录，并解压到此目录
3. `cp .env.example .env && vim .env`
4. 输入你的数据库信息和授权码
5. 进入 主机->进程守护，创建守护进程
6. 输入守护进程配置信息
    * name: 任何字符串
    * directory: 服务端代码根目录路径
    * command: npm run dev
7. 等待启动，进入守护进程的日志，找到管理员账户信息。

# 安装节点后端

    bash <(curl -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/install.sh)

