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

# create a server
bin/create-test-droplet 5495

# destroy it
bin/destroy-test-droplet 5495
```