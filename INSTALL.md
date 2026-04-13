# Installation

Below is a guide for configuring Apptainer to use a networking bridge to allow Ettercap to perform an ARP poison Man in the Middle Attack between containers running on the same EC2 host. These commands should be executed as the `root` on the system.

### Enable setuid

The Apptainer container needs to run as root in order to properly interact with the networking devices provided by the EC2 instance. First, we need to enable Set UID on the system and disable AppArmor restrictions on Set UID. 

Disable AppArmor protections for Set UID
```
sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

Install `uidmap` package in order to deploy the container as `root`
```
apt-get install -y uidmap
```

### Install Go

Apptainer is built on the Go compiler and language. We can install Go by downloading the binaries and unpacking them in `/usr/local`
```
wget https://go.dev/dl/go1.26.2.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.26.2.linux-amd64.tar.gz
```

Add Go binaries to `PATH` 
```
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
```

Log out and log in as root for the changes to take effect.

### Install Apptainer

We will be building Apptainer from source and using the default options which will allow executing containers as the `root` user.
```
wget https://github.com/apptainer/apptainer/releases/download/v1.4.5/apptainer-1.4.5.tar.gz
tar xf apptainer-1.4.5.tar.gz && cd apptainer-1.4.5/
```

Configure Apptainer.
```
./mconfig --localstatedir=/tmp
```

Change directories to the build directory.
```
cd /opt/src/apptainer/apptainer-1.4.5/builddir
```

Compile by executing `make` and `make install`
```
make && make install
```

### Building the container

Using the container definition file `ettercap.def` build the container image `ettercap.sif` using Apptainer.

```
apptainer build ettercap.sif ettercap.def
```

### Configure Network Bridge

In order to leverage the network bridge within our Apptainer containers we will need to install the `containernetworking-plugins` package in order for our container to interact with the network bridge defined within the EC2 instance.
```
apt-get install -y containernetworking-plugins
```

Create the configuration directories that the Apptainer configuration file `/usr/local/etc/apptainer/apptainer.conf` will search for the container plugin files.
```
mkdir -p /opt/cni/bin
ln -s /usr/lib/cni/* /opt/cni/bin/
mkdir -p /etc/cni/net.d
```

Create the definition file for the network bridge. You can choose any name for the brdige, replacing `bridge_name` in the configuration filename and contents below.
```
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

## Enable IP address forwarding

In order for the container to properly talk to the outside internet, the internal IP addresses of the network bridge must be able to be forwarded. Enable IPV4 IP forwarding.
```
sed -i '/net.ipv4.ip_forward/s/^#//' /etc/sysctl.conf
```

Next, add internal firewall rules within the instance to enable the IP forwarding from the container. You will need to specify the name of the network bridge you want to forward IPs from within these rules.
```
iptables -A FORWARD -i bridge_name-br0 -o ens5 -j ACCEPT
iptables -A FORWARD -i ens5 -o bridge_name-br0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```
