# Setting up a test in AWS using Cloudformation

# automatic way
../provision_coreos_stack.sh

#### ssh in and start the fleet service

fleetctl start /media/state/units/docker-base.1.service

fleetctl start /media/state/units/docker-base.2.service

fleetctl start /media/state/units/docker-base.3.service

# Manual way
### Create the stack
http://coreos.com/docs/running-coreos/cloud-providers/ec2/

or

For us-west-2
https://console.aws.amazon.com/cloudformation/home?region=us-west-2#cstack=sn%7ECoreOS-alpha%7Cturl%7Ehttps://s3.amazonaws.com/coreos.com/dist/aws/coreos-alpha.template

#### parameters

*Discovery URL* should be the value you get from https://discovery.etcd.io/new

*KeyPair* Should be the name of your KeyPair in aws

### Verify
At this point, etcd, ssh keys, and fleet should all be good. SSH into any machine using the *core* user. You can then verify by running `fleetctl list-machines`

#### Create the test service file

On any machine
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
Then run
```
fleetctl start /media/state/units/docker-base.1.service
```

Verify by running
```
fleetctl status docker-base.1.service
```

