# Installation Guide | [中文教程](https://github.com/pennyMorant/bunpanel-release/blob/dev/README_ZH.md) | [Demo](https://demo.bunpanel.com)
This tutorial is based on 1panel. The server requires authorization for use. If you need to test, please apply for a test authorization code from this BOT: [https://t.me/bunpanel_bot](https://t.me/bunpanel_bot)

# Environment
1. Go to the 1panel store and install OpenResty and PostgreSQL.
2. Prepare three domain names, which can be three subdomains, corresponding to the user frontend, admin frontend, and server.

# Install User Frontend
1. Create a website, select a static website, and enter the prepared user frontend domain.
2. enable website config gzip, edit config: gzip_static on;
3. Go to the website root directory, then enter the index directory and delete index.html.
4. Upload the frontend source code to this directory and unzip it.
5. Open config.json, modify apiUrl: http://server domain (authorization domain).
6. Now you should be able to access the frontend page.

# Install Admin Frontend
Same as the above steps, but the domain is the prepared admin frontend domain.

# Install Server
### Enter the server via SSH, create a folder, download the server program to this directory, and unzip it.
    mkdir /var/www/bun
    cp .env.example .env
### Edit .env DB_USERNAME=database user DB_PASSWORD=database password APP_LICENSE=authorization code
### Go back to 1panel, create a website, choose reverse proxy. Here, enter the prepared server domain (authorization domain) as the domain, and enter: 127.0.0.1:3000 as the proxy address.
### Go back to SSH, enter the directory /var/www/bun, then execute ./bunpanel-x64.
### Now you can see the output log, the red part is the admin username and password.

# Daemon Process
    [program:bunpanel]
    directory=/var/www/bun
    command=/var/www/bun/bunpanel-x64
    user=root
    autostart=true
    autorestart=true
    numprocs=1
    redirect_stderr=true
    stdout_logfile=/var/log/supervisor/bunpanel.log
### Copy the above code and execute the code.
    vim /etc/supervisor/conf.d/bun.conf
### Paste the copied code, save and exit. Then execute
    supervisorctl reread
    supervisorctl update
    supervisorctl start bunpanel

# Install Server Backend

    bash <(curl -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/install.sh)

