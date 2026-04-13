# CSC 348 Ettercap Lab
An apptainer implmentation for ARP poisoning across containers running on Amazon EC2

## Accessing your Virtual Machine

### Log in

For this lab you will need to connect multiple times to your virtual machine in order to properly deploy an Apptainer container for both the attacker and victim hosts. To connect to your VM log as the `seed` user and edit the hostname of the VM and change `USER` to your WFU username (email address without @wfu.edu).

```
ssh seed@ettercap.USER.cs.ar53.wfu.edu
```

Once connected ensure that the temporary session directory for Apptainer exists.
```
mkdir -p /tmp/apptainer/mnt/session
```

Then you can start the attacking container by excuting the following command:
```
sudo ./start_attacker.sh
```
This script is essentially a wrapper script that deploys the Apptainer container with the following options:
```
apptainer shell --net --network 1234567890 --hostname seed-container --dns 8.8.8.8 --add-caps NET_RAW,NET_ADMIN ettercap.sif
```

You should see the following prompt if the container successfully deployed
```
[Apptainer-Security-Lab] /home/seed $
```

This container is connected to an isolated network within your VM, and each time you deploy a container it will receive a new IP address within the IP range `10.22.0.0/24`. The default gateway for this VLAN is `10.22.0.1` and you should always see that default gateway IP no matter the number of containers you deploy. The first container you deploy within your VM will have the IP `10.22.0.2`, the second will have the IP `10.22.0.3`, and so on.

You can always verify the IP address that was assigned to your container with the command `ip a`
```
ip a
```
<details>
<summary> IP Info Example: </summary>
```
2: eth0@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether ea:65:98:60:38:e7 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.22.0.2/24 brd 10.22.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::e865:98ff:fe60:38e7/64 scope link 
       valid_lft forever preferred_lft forever
```
<\details>


## Installation
### Enable IP address forwarding
```
echo 1 > /proc/sys/net/ipv4/ip_forward
```

### Enable setuid
```
sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
apt-get install -y uidmap
```

### Install Go
```
wget https://go.dev/dl/go1.26.2.linux-amd64.tar.gz

tar -C /usr/local -xzf go1.26.2.linux-amd64.tar.gz

echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
```
### Install Apptainer
```
wget https://github.com/apptainer/apptainer/releases/download/v1.4.5/apptainer-1.4.5.tar.gz

tar xf apptainer-1.4.5.tar.gz
cd apptainer-1.4.5/

./mconfig --localstatedir=/tmp
cd /opt/src/apptainer/apptainer-1.4.5/builddir

make
make install
```

### Configure Network Bridge
```
apt-get install -y containernetworking-plugins
mkdir -p /opt/cni/bin
ln -s /usr/lib/cni/* /opt/cni/bin/
mkdir -p /etc/cni/net.d

cat > /etc/cni/net.d/bridge_name.conflist << EOF
{
    "cniVersion": "0.4.0",
    "name": "bridge_name",
    "plugins": [
        {
            "type": "bridge",
            "bridge": "bridge_name-br0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.22.0.0/24",
                "routes": [
                    { "dst": "0.0.0.0/0" }
                ]
            }
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true}
        }
    ]
}
EOF
```

### Add iptables rules for IP forwarding
```
iptables -A FORWARD -i 1234567890-br0 -o ens5 -j ACCEPT
iptables -A FORWARD -i ens5 -o 1234567890-br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```
