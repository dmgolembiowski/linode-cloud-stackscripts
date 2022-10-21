# linode/django-one-click.sh by linode
# id: 609175
# description: http://$ipaddress:8000
# defined fields: name-djangouser-label-django-user-example-user1-name-djangouserpassword-label-django-password-example-s3cure_p4ssw0rd-name-djangouseremail-label-django-user-email-example-useremailtld
# images: ['linode/debian10']
# stats: Used By: 167 + AllTime: 2423
#!/bin/bash
#<UDF name="djangouser" Label="Django USER" example="user1" />
#<UDF name="djangouserpassword" Label="Django Password" example="s3cure_p4ssw0rd" />
#<UDF name="djangouseremail" Label="Django USER email" example="user@email.tld" />

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install Python & Django
apt-get install -y python3 python3-pip
pip3 install Django

# Create & Setup Django APP
mkdir /var/www/
cd /var/www/
django-admin startproject DjangoApp
cd DjangoApp
python3 manage.py migrate
echo "from django.contrib.auth.models import User; User.objects.create_superuser('$DJANGOUSER', '$DJANGOUSEREMAIL', '$DJANGOUSERPASSWORD')" | python3 manage.py shell
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['$IP'\]/g" DjangoApp/settings.py
python3 manage.py runserver 0.0.0.0:8000 &

# Start Django app on reboot
crontab -l | { cat; echo "@reboot cd /var/www/DjangoApp && python3 manage.py runserver 0.0.0.0:8000 &"; } | crontab -

# Cleanup
stackscript_cleanup