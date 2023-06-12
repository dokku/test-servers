#!/usr/bin/env bash
set -eo pipefail

sudo apt-get update -qq >/dev/null
sudo apt-get -qq -y --no-install-recommends install apt-transport-https build-essential git unzip

# clone the repo
git clone https://github.com/dokku/dokku.git /root/dokku
git -C /root/dokku checkout COMMIT_REF

# install docker
wget -nv -O - https://get.docker.com/ | sh

# install dokku
wget -qO- https://packagecloud.io/dokku/dokku/gpgkey | sudo tee /etc/apt/trusted.gpg.d/dokku.asc
OS_ID="$(lsb_release -cs 2>/dev/null || echo "jammy")"
echo "focal jammy" | grep -q "$OS_ID" || OS_ID="jammy"
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | sudo tee /etc/apt/sources.list.d/dokku.list
sudo apt-get update -qq >/dev/null

curl -sL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer GITHUB_TOKEN" https://api.github.com/repos/dokku/dokku/actions/artifacts/ARTIFACT_ID/zip -o /tmp/build.zip
cd /tmp || exit 1
unzip /tmp/build.zip
export DEBIAN_FRONTEND=noninteractive
echo "dokku dokku/vhost_enable boolean true" | sudo debconf-set-selections
echo "dokku dokku/hostname string $(wget -qO- https://ipinfo.io/ip).sslip.io" | sudo debconf-set-selections
echo "dokku dokku/skip_key_file boolean false" | sudo debconf-set-selections
echo "dokku dokku/key_file string /root/.ssh/authorized_keys" | sudo debconf-set-selections
echo "dokku dokku/nginx_enable boolean true" | sudo debconf-set-selections
sudo apt-get -qq -y install /tmp/dokku_*amd64.deb

# install test devtools
pushd /root/dokku
make ci-dependencies setup-deploy-tests
popd
