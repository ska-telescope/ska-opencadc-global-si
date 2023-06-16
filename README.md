# CADC Storage Inventory -- global site deployment
This repository contains an ansible playbook for deployment and instatiation of a global site storage inventory, along with the required configuration files. Both the ansible playbook and the configuration files will quite likely need some tweaking for your local installation.
## Pre-requisites
- SSL certificates for the host on the host (check out `make-self-signed-ssl-certs.sh` or create them via letsencrypt.org)

In addition, you need to add the target host in `inventories/hosts` unless you're just doing an install on `localhost` (default in the ansible playbook).

You'll also need to have the latest ansible version.

Example: Ubuntu version
```
sudo apt update
sudo apt upgrade
sudo apt install ansible
```

## Storage inventory components diagram

![SI](https://github.com/opencadc/storage-inventory/raw/master/docs/storage-site.png)

## Components required for a global storage site
The below components can either be build from scratch as docker images using the description from the [CADC-Storage Inventory github](https://github.com/opencadc/storage-inventory) or they can be pulled from the [CADC docker image repository](https://images.opencadc.org/)(requires login). Descriptions of how to query what resources are available can be found [here](https://www.opencadc.org/storage-inventory/ops/). Pulling the images requires no login.

### Must have
 - reg (the global registry that contains info about which services lives at which URL)
 - baldur (permission information)
 - raven (implements transfer negotiation in a global inventory deployment)
 - luskan (handles the metadata)
 - postgres database server (e.g. [postgresql from CADC](https://github.com/opencadc/docker-base/tree/master/cadc-postgresql-dev))
 - proxy server (e.g. [haproxy from CADC](https://github.com/opencadc/docker-base/tree/master/cadc-haproxy-dev))
 - ratik (validates all metadata between local site and a remote site, e.g. global site, one instance per connected local site)
 - fenwick (synchronises metadata between local site and remote site in an incremental fashion, one instance per connected local site)

## Ansible deployment of CADC Storage Inventory local site
The ansible playbook will:
 - install dependencies like docker, pip, acl
 - create directories for the config files, for logs, for ssl-certificates, for the actual data
 - pull the required images from images.opencadc.org/storage-inventory
 - launch the containers and bind-mount the respective config files and where required the data directory into the contaiers.
 - check out `vars.template.yaml` on parameters that need to be set for this playbook to work

The only complication will be that you will need to put the SSL-certificates into the certificates directory specified in the playbook file. The server's public + private key need to be in a file called server-cert.pem and the client's CA-certificates will need to be in the subdirectory `cacerts` inside the certificates directory.

### Run Playbook
```
ansible-playbook [-i inventories/hosts] install.yml
```
If you get a error during the deployment, remember to remove all created containers
```
docker rm -f $(docker ps -a -q)
```

## Testing deployment
 - test if services are online and available via the availability hooks described [here](https://www.opencadc.org/storage-inventory/ops/#deployment) (e.g. for luskan: `curl https://www.example.org/luskan/availability`)

## TechDebt

- Export HAproxy configuration to solve the Warning: 
```
[WARNING] 348/090903 (19) : Setting tune.ssl.default-dh-param to 1024 by default, if your workload permits it you should set it to at least 2048. Please set a value >= 1024 to make this warning disappear.
```
- Check `/conf` and `/config` within HAProxy deployment and Documentation.
- Problem with underscores and middle dash for DBs and Scheme
- `OpaqueFileSystemStorageAdapter.org.opencadc.inventory.storage.fs.baseDir` ?
  - `#org.opencadc.inventory.storage.fs.baseDir = /tmp/`
  - `org.opencadc.inventory.storage.fs.OpaqueFileSystemStorageAdapter.baseDir = /tmp`
