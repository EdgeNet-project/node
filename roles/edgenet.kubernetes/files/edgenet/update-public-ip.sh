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

if az >/dev/null; then
  intip=$(az network/interface/0/ipv4/ipAddress/0/privateIpAddress)
  # The NIC public IP is not available through Azure metadata...
  # https://docs.microsoft.com/en-us/answers/questions/7932/public-ip-not-available-via-metadata.html
  pubip=$(pubip)
elif aws >/dev/null; then
  intip=$(aws local-ipv4)
  pubip=$(aws public-ipv4)
elif gcp >/dev/null; then
  intip=$(gcp network-interfaces/0/ip)
  pubip=$(gcp network-interfaces/0/access-configs/0/external-ip)
elif scw >/dev/null; then
  intip=$(scw PRIVATE_IP)
  pubip=$(scw PUBLIC_IP_ADDRESS)
else
  echo "KUBELET_EXTRA_ARGS=--cgroup-driver=systemd" | tee >/etc/default/kubelet
  exit
fi

# Find the interface which has the internal IP.
dev=$(ip --brief addr | grep "${intip}" | cut -d ' ' -f 1)

# Add the public IP address to the public interface (if not already).
if ip --brief addr show dev "${dev}" | grep -v "${pubip}"; then
  ip addr add "${pubip}/32" dev "${dev}"
fi

# Rewrite the destination IP address of incoming packets with the public IP.
chain="PREROUTING"
rule="--table nat --jump DNAT --source ${intip} --to ${pubip}"
if ! iptables --check ${chain} ${rule} 2>/dev/null; then
  iptables --append ${chain} ${rule}
fi

# Rewrite the source IP address of outgoing packet with the internal IP.
# Some providers filter packets with a source IP != internal IP.
chain="POSTROUTING"
rule="--table nat --jump SNAT --source ${pubip} --to ${intip}"
if ! iptables --check ${chain} ${rule} 2>/dev/null; then
  iptables --append ${chain} ${rule}
fi

# Configure kubelet to use the public IP as the node IP.
echo "KUBELET_EXTRA_ARGS=--node-ip ${pubip}" | tee >/etc/default/kubelet
