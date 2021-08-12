#!/bin/bash

HOME="/home/${SUDO_USER}"

# This script should be run with root privileges
apt update -y && apt upgrade -y

# Use nginx as web server and python3 to install certbot
apt install nginx python3 python3-venv libaugeas0 -y -y

python3 -m venv /opt/certbot/
/opt/certbot/bin/pip install --upgrade pip
/opt/certbot/bin/pip install certbot certbot-nginx certbot-dns-cloudflare
ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Get user parameters
read -p "Enter Record name (subdomain): " SUBDOMAIN
read -p "Enter Cloudflare API Token: " TOKEN
read -p "Enter Cloudflare Zone Identifier: " ZONE
read -p "Enter Target Interface: " INTERFACE
read -p "Enter Email (only for urgent LetsEncrypt security notifications. Can be left blank): " EMAIL

# Create cloudflare.ini file that contains API Token
mkdir -p ${HOME}/.secrets && touch ${HOME}/.secrets/cloudflare.ini
echo "dns_cloudflare_api_token = ${TOKEN}" > ${HOME}/.secrets/cloudflare.ini
chmod 600 ${HOME}/.secrets/cloudflare.ini

# Create default NGINX configuration
cp nginx_template default
sed -i "s/%SUBDOMAIN%/${SUBDOMAIN}/" default

# Modify ddns updater script and make executable
cp update_template.sh update.sh
sed -i "s/%TOKEN%/${TOKEN}/" update.sh
sed -i "s/%ZONE%/${ZONE}/" update.sh
sed -i "s/%SUBDOMAIN%/${SUBDOMAIN}/" update.sh
sed -i "s/%INTERFACE%/${INTERFACE}/" update.sh
chmod +x update.sh

# Copy script to cron.d and add to crontab
cp update.sh /usr/local/sbin/local_ssl_cloudflare_ddns_updater.sh
touch /etc/cron.d/ddns_update
echo "*/5 * * * * /etc/cron.d/local_ssl_cloudflare_ddns_updater.sh" > /etc/cron.d/ddns_update

# Fetch certificate with Certbot
if [ "${EMAIL}" == "" ]; then
    CERTBOT_CMD="--register-unsafely-without-email"
else
    CERTBOT_CMD="--no-eff-email -m ${EMAIL}"
fi

certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
    --non-interactive --agree-tos ${CERTBOT_CMD} \
    -d "${SUBDOMAIN}"

# Add renewal script to crontab
echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; \
    time.sleep(random.random() * 3600)' && certbot renew -q" | \
    sudo tee -a /etc/crontab > /dev/null

# Copy across new config and restart nginx
cp default /etc/nginx/sites-available/default
nginx -s reload
