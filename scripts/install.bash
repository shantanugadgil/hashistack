#!/bin/bash

#yum install -y wget unzip

# install the Consul binary
wget -nv https://releases.hashicorp.com/consul/1.5.1/consul_1.5.1_linux_amd64.zip -O consul.zip
unzip -o consul.zip
sudo chown root:root consul
sudo mv -fv consul /usr/sbin/

# install the Nomad binary
wget -nv https://releases.hashicorp.com/nomad/0.9.3/nomad_0.9.3_linux_amd64.zip -O nomad.zip
unzip -o nomad.zip
sudo chown root:root nomad
sudo mv -fv nomad /usr/sbin/

# install Consul's service file
wget -nv https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/consul.service -O consul.service
sudo chown root:root consul.service
sudo mv -fv consul.service /etc/systemd/system/consul.service

# install Nomad's service file
wget -nv https://raw.githubusercontent.com/shantanugadgil/hashistack/master/systemd/nomad.service -O nomad.service
sudo chown root:root nomad.service
sudo mv -fv nomad.service /etc/systemd/system/nomad.service

