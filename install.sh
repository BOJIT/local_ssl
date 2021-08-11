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
read -p "Enter top-level domain: " DOMAIN
read -p "Enter device subdomain: " SUBDOMAIN
read -p "Enter Cloudflare API Token: " TOKEN

# Create cloudflare.ini file that contains API Token
mkdir -p $HOME/.secrets && touch $HOME/.secrets/cloudflare.ini
echo "dns_cloudflare_api_token = ${TOKEN}" > $HOME/.secrets/cloudflare.ini

# Create default NGINX configuration
cp nginx_config default
sed -i "s/#SUBDOMAIN/${SUBDOMAIN}/" default
