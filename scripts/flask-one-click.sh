# linode/flask-one-click.sh by linode
# id: 609392
# description: Flask One-Click
# defined fields: 
# images: ['linode/debian10']
# stats: Used By: 107 + AllTime: 1426
#!/bin/bash

## Enable logging
exec > /var/log/stackscript.log 2>&1
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>
## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>
## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>
## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

set -o pipefail
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update
ufw_install
ufw allow http

# Install Prereq's & Flask APP
apt install -y git
cd /home
git clone https://github.com/abalarin/Flask-on-Linode.git flask_app_project

# Install & configure Nginx
apt install -y nginx
cat <<END > /etc/nginx/sites-enabled/flask_app
server {
    listen 80;
    server_name $IP;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
END

unlink /etc/nginx/sites-enabled/default
nginx -s reload

# Install python & Packages
apt install -y python3 python3-pip
cd /home/flask_app_project
pip3 install -r flask_app/requirements.txt

# Configure Flask
cat <<END > /etc/config.json
{
  "SECRET_KEY": "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)",
  "SQLALCHEMY_DATABASE_URI": "sqlite:///site.db"
}
END

cat <<END > /home/flask_app_project/flask_app/__init__.py
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
import json
import urllib3
app = Flask(__name__)
with open('/etc/config.json') as config_file:
  config = json.load(config_file)
app.config['SECRET_KEY'] = config.get('SECRET_KEY')
app.config['SQLALCHEMY_DATABASE_URI'] = config.get('SQLALCHEMY_DATABASE_URI')
db = SQLAlchemy(app)
login_manager = LoginManager()
login_manager.init_app(app)
from flask_app import routes
END

# Install and Configure Gunicorn
apt install -y gunicorn3
gunicorn3 --workers=3 flask_app:app &

# Install and Configure Supervisor
apt install -y supervisor
cat <<END > /etc/supervisor/conf.d/flask_app.conf
[program:flask_app]
directory=/home/flask_app_project
command=gunicorn3 --workers=3 flask_app:app
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/flask_app/flask_app.err.log
stdout_logfile=/var/log/flask_app/flask_app.out.log
END

mkdir /var/log/flask_app
touch /var/log/flask_app/flask_app.out.log
touch /var/log/flask_app/flask_app.err.log
supervisorctl reload

# Cleanup
stackscript_cleanup