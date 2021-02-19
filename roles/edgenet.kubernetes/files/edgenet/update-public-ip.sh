#!/bin/sh
# shellcheck disable=SC2086
# vim: et sw=2 ts=2
set -eux

# Cloud providers assign a public IP to instances through NAT.
# The instance only sees an private _internal_ IP.
# This is problematic for Kubernetes, which expects to see the public IP on the interface.
# In this script, we assign the public IP to the instance interface.
# TODO: Should this be in an Ansible playbook instead?

. /opt/edgenet/common.sh

dev="unknown"   # Interface name
intip="unknown" # Internal IP
pubip="unknown" # Public IP

if ec2 >/dev/null; then
  intip=$(ec2 local-ipv4)
  pubip=$(ec2 public-ipv4)
elif gcp >/dev/null; then
  intip=$(gcp network-interfaces/0/ip)
  pubip=$(gcp network-interfaces/0/access-configs/0/external-ip)
elif scw >/dev/null; then
  intip=$(scw PRIVATE_IP)
  pubip=$(scw PUBLIC_IP_ADDRESS)
fi

# Find the interface which has the internal IP.
dev=$(ip --brief addr | grep "${intip}" | cut -d ' ' -f 1)

# Add the public IP address to the public interface (if not already).
if ip --brief addr show dev "${dev}" | grep -v "${pubip}"; then
  ip addr add "${pubip}/32" dev "${dev}"
fi

# Rewrite the source IP address of outgoing packet with the internal IP.
# Some providers filter packets with a source IP != internal IP.
chain="POSTROUTING"
rule="--table nat --jump SNAT --source ${pubip} --to ${intip}"
if ! iptables --check ${chain} ${rule} 2>/dev/null; then
  iptables --append ${chain} ${rule}
fi

# Configure kubelet to use the public IP as the node IP.
# TODO: It should not be needed to set the cgroup driver here.
echo "KUBELET_EXTRA_ARGS=--cgroup-driver systemd --node-ip ${pubip}" | tee >/etc/default/kubelet
