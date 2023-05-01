Olympus Cluster
====
Highly opinionated a single [k3s](https://k3s.io) cluster with [Ansible](https://www.ansible.com) and [Terraform](https://www.terraform.io) backed by [Flux](https://toolkit.fluxcd.io/) and [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/).

[![Cluster](https://img.shields.io/uptimerobot/status/m794263735-348debae056e127588fd93e5?color=brightgreeen&label=Status&style=for-the-badge&logo=v&logoColor=white)](https://k8s.itstoni.com)
[![ClusterUptime](https://img.shields.io/uptimerobot/ratio/7/m794263735-348debae056e127588fd93e5?logo=V&logoColor=white&style=for-the-badge)](https://k8s.itstoni.com)


# TL;DR

### Configuration
```sh
task init
task precommit:init
task precommit:update
cp .config.sample.env .config.env
cp .envrc.dist.env.envrc
```
Start configure ```.envrc``` and ```.config.env``` check configuration with:
```sh
task verify
```
And runs this command after succeeded:
```sh
task configure
```

### Install
#### prepare nodes step:
```sh
task an:init
task an:list
task an:ping

# start preparing your nodes
task an:prepare

# run this command if ansible not rebooting the nodes:
task an:force-reboot
```

#### k3s install step:
```sh
task an:list
task an:ping
task an:install
```

#### cluster install:
```sh
# push your changes to github first
git add . -A
git commit  -am "initial commit"
git push

# label your node first if required
# task cl:label olympus/role=node_role

# start installation
task cl:verify
task cl:install

# verify install
task cl:pods -- -n flux-system
```


### Notes
Root on zfs node should creating zfs vol for rancher:
```sh

zfs create -s -V 100GB tank/rancher
mkfs.ext4 /dev/zvol/zpool/tank/rancher
echo "/dev/zd0 /var/lib/rancher ext4 defaults,_netdev 0 0" >> /etc/fstab
mkdir -p /var/lib/rancher
mount /var/lib/rancher
```
