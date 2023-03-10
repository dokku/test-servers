#!/usr/bin/env bash

sudo apt-get update -qq >/dev/null
sudo apt-get -qq -y --no-install-recommends install apt-transport-https unzip

# install docker
wget -nv -O - https://get.docker.com/ | sh

# install dokku
wget -qO- https://packagecloud.io/dokku/dokku/gpgkey | sudo tee /etc/apt/trusted.gpg.d/dokku.asc
OS_ID="$(lsb_release -cs 2>/dev/null || echo "bionic")"
echo "bionic focal jammy" | grep -q "$OS_ID" || OS_ID="bionic"
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | sudo tee /etc/apt/sources.list.d/dokku.list
sudo apt-get update -qq >/dev/null

cd /tmp || exit 1
export DEBIAN_FRONTEND=noninteractive
echo "dokku dokku/vhost_enable boolean true" | sudo debconf-set-selections
echo "dokku dokku/hostname string $(wget -qO- https://ipinfo.io/ip).sslip.io" | sudo debconf-set-selections
echo "dokku dokku/skip_key_file boolean false" | sudo debconf-set-selections
echo "dokku dokku/key_file string /root/.ssh/authorized_keys" | sudo debconf-set-selections
echo "dokku dokku/nginx_enable boolean true" | sudo debconf-set-selections

wget https://dokku.com/install/master/bootstrap.sh
sudo DOKKU_BRANCH=master bash bootstrap.sh
