# CSC348-ettercap
An apptainer implmentation for ARP poisoning across containers running on Amazon EC2

## Installation
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
