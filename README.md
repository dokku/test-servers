# test-servers

Manages test servers on Digitalocean for Dokku pull requests.

## Requirements

- curl
- jq

## Usage

```shell
# set the required environment variables
# - DIGITALOCEAN_TOKEN
# - DIGITALOCEAN_VPC_UUID
# - DIGITALOCEAN_PROJECT_ID
# - DIGITALOCEAN_SSH_KEY_ID
# - GITHUB_TOKEN

# create and destroy a server based on a PR
bin/create-test-droplet "5495"
bin/destroy-test-droplet "5495"

# create one for a given issue that installs latest dokku
bin/create-test-droplet 4782 "issue"
bin/destroy-test-droplet 4782 "issue"

# create a server from a source install
bin/create-test-droplet 4782 "source"
bin/destroy-test-droplet 4782 "source"
```