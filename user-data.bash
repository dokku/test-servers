#!/usr/bin/env bash
set -eo pipefail
set -x

sudo apt-get update -qq >/dev/null
sudo apt-get -qq -y --no-install-recommends install apt-transport-https bat build-essential git unzip
sudo apt-add-repository -y ppa:zanchey/asciinema
sudo apt-get update -qq >/dev/null
sudo apt-get install -y asciinema

# clone the repo
dokku_clone_root="/root/go/src/github.com/dokku/dokku"
mkdir -p /root/go/src/github.com/dokku /root/.cache/go-build
git clone https://github.com/dokku/dokku.git "$dokku_clone_root"
commit_ref="COMMIT_REF"
if [[ -n "$commit_ref" ]]; then
  git -C "$dokku_clone_root" checkout "$commit_ref"
fi

# install go
GOLANG_VERSION="$(grep BUILD_IMAGE "$dokku_clone_root/common.mk" | cut -d' ' -f3 | cut -d':' -f2)"
curl -o "/tmp/go${GOLANG_VERSION}.linux.tar.gz" -L "https://go.dev/dl/go${GOLANG_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
tar -C /usr/local -xzf "/tmp/go${GOLANG_VERSION}.linux.tar.gz"
# shellcheck disable=SC2016
echo 'export GOCACHE=/root/.cache/go-build' >>/etc/profile
echo 'export GOPATH=/root/go' >>/etc/profile
echo 'export PATH=$PATH:/usr/local/go/bin' >>/etc/profile
echo 'export PLUGIN_MAKE_TARGET=build' >>/etc/profile

# install gopls, go-outline, go-symbols
export PATH=$PATH:/usr/local/go/bin
export GOCACHE=/root/.cache/go-build
export GOPATH=/root/go
go install -v github.com/cweill/gotests/gotests@latest
go install -v github.com/fatih/gomodifytags@latest
go install -v github.com/go-delve/delve/cmd/dlv@latest
go install -v github.com/josharian/impl@latest
go install -v github.com/newhook/go-symbols@latest
go install -v github.com/ramya-rao-a/go-outline@latest
go install -v golang.org/x/tools/gopls@latest
go install -v honnef.co/go/tools/cmd/staticcheck@latest

# install docker
wget -nv -O - https://get.docker.com/ | sh

# install dokku
wget -qO- https://packagecloud.io/dokku/dokku/gpgkey | sudo tee /etc/apt/trusted.gpg.d/dokku.asc
OS_ID="$(lsb_release -cs 2>/dev/null || echo "jammy")"
echo "focal jammy" | grep -q "$OS_ID" || OS_ID="jammy"
echo "deb https://packagecloud.io/dokku/dokku/ubuntu/ ${OS_ID} main" | sudo tee /etc/apt/sources.list.d/dokku.list
sudo apt-get update -qq >/dev/null

artifact_id="ARTIFACT_ID"
if [[ -n "$artifact_id" ]] && [[ "$artifact_id" != "none" ]]; then
  curl -sL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer GITHUB_TOKEN" "https://api.github.com/repos/dokku/dokku/actions/artifacts/$artifact_id/zip" -o /tmp/build.zip
  cd /tmp || exit 1
  unzip /tmp/build.zip
fi

cd /tmp || exit 1
export DEBIAN_FRONTEND=noninteractive
echo "dokku dokku/vhost_enable boolean true" | sudo debconf-set-selections
echo "dokku dokku/hostname string ISSUE_ID.dokku.dev" | sudo debconf-set-selections
echo "dokku dokku/skip_key_file boolean false" | sudo debconf-set-selections
echo "dokku dokku/key_file string /root/.ssh/authorized_keys" | sudo debconf-set-selections
echo "dokku dokku/nginx_enable boolean true" | sudo debconf-set-selections

source_type="SOURCE_TYPE"
if [[ "$source_type" == "pr" ]]; then
  sudo apt-get -qq -y install /tmp/dokku_*amd64.deb
elif [[ "$source_type" == "issue" ]]; then
  sudo apt-get -qq -y install dokku
elif [[ "$source_type" == "source" ]]; then
  wget https://dokku.com/install/master/bootstrap.sh
  sudo DOKKU_BRANCH=master bash bootstrap.sh
else
  exit 1
fi

dokku domains:set-global ISSUE_ID.dokku.dev

# setup letsencrypt
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# install test devtools
pushd "$dokku_clone_root"
.devcontainer/bin/setup-dev-env

popd
