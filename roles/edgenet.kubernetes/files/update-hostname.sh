#!/bin/sh
set -eux

# Some hosts change their hostname on boot,
# we (re)set the correct hostname here.

hostname=$(cat /etc/edgenet-hostname)

# Update /etc/hostname
hostnamectl set-hostname "${hostname}"

# Update /etc/hosts
sed -i.bak '/.edgenet.io$/d' /etc/hosts
echo "127.0.0.1 ${hostname}" | tee -a /etc/hosts

# Restart kubelet if installed
if systemctl list-unit-files | grep kubelet.service > /dev/null; then
    systemctl restart kubelet
fi
