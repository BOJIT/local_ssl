#!/bin/bash

HOME="/home/$SUDO_USER"

# This script should be run with root privileges
apt update -y && apt upgrade -y

# Use nginx as web server and snapd to install certbot
apt install nginx snapd -y

# Update snapd and install certbot
snap install core; snap refresh core
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

# Get user parameters
read -p "Enter Record name (subdomain): " SUBDOMAIN
read -p "Enter Cloudflare API Token: " TOKEN
read -p "Enter Cloudflare Zone Identifier: " ZONE
read -p "Enter Target Interface: " INTERFACE

# Create cloudflare.ini file that contains API Token
mkdir -p $HOME/.secrets && touch $HOME/.secrets/cloudflare.ini
echo "dns_cloudflare_api_token = ${TOKEN}" > $HOME/.secrets/cloudflare.ini

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


# Fetch certificate and check for auto-renewal


# Restart nginx
