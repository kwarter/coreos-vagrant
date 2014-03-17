# Summary
Set up a working demo with 3 VMs, coreos and fleet

## Get etcd working on the 3 nodes
stop etcd on all machines since it's not setup properly
```
sudo systemctl stop etcd
```
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
		How do I distribute the discovery initially and get the peers to know about each other?



## Get the container deployed to each node via systemd unit file

On core1
```
sudo vi /media/state/units/docker-base.1.service
```
```
[Unit]
Description=docker-base
After=docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash -c '/usr/bin/docker start -a tony-container || /usr/bin/docker run -p 40022:22 -p 8081:8081 --expose=[22,8081] --name=tony-container monstaloc/docker-base /usr/sbin/sshd -D'
ExecStop=/usr/bin/docker stop tony-container

[X-Fleet]
X-Conflicts=docker-base.*.service
```


## Fleet
### Configuration
On all nodes
https://github.com/coreos/fleet/blob/master/Documentation/configuration.md

core1
```
vi fleet.conf
```
```
public_ip=192.168.2.101
```
core2
```
vi fleet.conf
```
```
public_ip=192.168.2.102
```
core3
```
vi fleet.conf
```
```
public_ip=192.168.2.103
```

### SSH keys

setup a ssh distribute script. you will need this so that fleet can do things on other boxes

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
Execute
```
chmod +x fleetctl-inject-ssh.sh
ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
cat ~/.ssh/id_rsa.pub | ./fleetctl-inject-ssh.sh core
```



### Start fleet on all machines
Configure your own fleet unit because coreos has RO mounts
(ie /usr/lib64/systemd/system/fleet.service)
``` 
sudo vi /media/state/units/fleet2.service
```
```
[Unit]
Description=fleet

[Service]
ExecStart=/usr/bin/fleet --config /home/core/fleet.conf

[Install]
WantedBy=multi-user.target

```

```
sudo systemctl link --runtime /media/state/units/fleet2.service
```
```
sudo systemctl start fleet2.service
```

Verify by running `fleetctl list-machines`

on core1
```
fleetctl start /media/state/units/docker-base.1.service
```

verify by running `fleetctl status docker-base.1.service`

## Optional
If you want to ssh directly to your VMs via name, do this once on your mac
```
vagrant ssh-config  core1 >> ~/.ssh/config
varant ssh-config  core2 >> ~/.ssh/config
vagrant ssh-config  core3 >> ~/.ssh/config
```
