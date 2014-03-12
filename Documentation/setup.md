# How to setup stuff

## Get etcd working on the 3 nodes

sudo systemctl stop etcd
core1
```
/usr/bin/etcd -name 1 -peer-addr 192.168.2.101:7001 -addr 192.168.2.101:4001 
```
core2
```
/usr/bin/etcd -name 2 -peer-addr 192.168.2.102:7001 -addr 192.168.2.102:4001 -peers=192.168.2.101:7001 
```
core3
```
/usr/bin/etcd -name 3 -peer-addr 192.168.2.103:7001 -addr 192.168.2.103:4001 -peers=192.168.2.102:7001
```
Questions: 
		How do I distribute the discovery initially and get the peers to undestand each other?



## Get the container deployed to each node via systemd unit file
```
sudo vi /media/state/units/docker-base.service
```
```
[Unit]
Description=docker-base
After=docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash -c '/usr/bin/docker start -a tony-container || /usr/bin/docker run -p 40022:22 -p 8081:8081 --expose=[22,8081] --name=tony-container monstaloc/docker-base /usr/sbin/sshd -D'
ExecStop=/usr/bin/docker stop tony-container
```

Do this one time only on your host machine (mac), when you first do this because you will need to setup fleetctl tunneling. 

vagrant ssh-config  core1 >> ~/.ssh/config
varant ssh-config  core2 >> ~/.ssh/config
vagrant ssh-config  core3 >> ~/.ssh/config


## Fleet
### Configuration
On all nodes
https://github.com/coreos/fleet/blob/master/Documentation/configuration.md
```
vi fleet.conf
```
```
public_ip=192.168.2.101
```

### SSH keys

setup a ssh distribute script

```
vi fleetctl-inject-ssh.sh

#!/bin/bash -x

name=$1
if [ -z $name ]; then
	echo "Provide a name for the injected SSH key"
	exit 1
fi

shift 1

pubkey=$(cat)

for machine in $(fleetctl $@ list-machines --no-legend -l | awk '{ print $1;}'); do fleetctl $@ ssh $machine "echo '${pubkey}' | update-ssh-keys -a $name -n"
done


```
chmod +x fleetctl-inject-ssh.sh

ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""




### Start fleet
```
fleet --config fleet.conf &
fleetctl list-machines
```


on one node
	fleetctl start docker-base.service

