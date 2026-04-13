# CSC348-ettercap
An apptainer implmentation for ARP poisoning across containers running on Amazon EC2

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
