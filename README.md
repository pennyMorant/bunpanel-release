# BunPanel Features
* The server is implemented using nodejs
* The front end uses vue3 + typescript + pinia + material design3
* The server uses binary files to run and is easy to install.
* Supports one-click installation of backend services
* Support setting up reverse proxy service
* More new features

# Installation Guide | [中文教程](https://github.com/pennyMorant/bunpanel-release/blob/dev/README_ZH.md) | [Demo](https://demo.bunpanel.com) | [Telegram](https://t.me/bunpanel)
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
1. Create a website, select revers proxy, and enter the server domain
2. go to the website root dirctory,then into index directory and upload server souce code
3. `cp .env.example .env && vim .env`
4. enter your database info, license
5. go to Host->Supervisor, and create daemon process
6. enter config for daemon process
    * name: any string
    * directory: your server source code directory
    * command: npm run dev
7. await start , then go to daemon process log. finding admin account info in log

# Install Server Backend

    bash <(curl -Ls https://raw.githubusercontent.com/pennyMorant/bunpanel-release/dev/server/install.sh)

