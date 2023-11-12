# 安装教程
此教程基于1panel
服务端需要授权使用，如需测试请在此BOT申请测试授权码https://t.me/bunpanel_bot
# 安装前端
1. 打开1panel，进入商店安装 openresty
2. 创建网站，选择静态网站
3. 进入网站根目录，然后进入index目录删除index.html
4. 上传前端源码到此目录，并解压
5. 打开config.json ，然后修改值为服务端的URL
6. 现在应该可以访问前端页面了
# 安装服务端
      bash <(curl -Ls https://raw.githubusercontent.com/zeropanel/bunpanel-release/dev/install.sh)
