#!/bin/sh
# shellcheck disable=SC2086
set -eux

# Cloud providers assign a public IP to instances through NAT.
# The instance only sees an private _internal_ IP.
# This is problematic for Kubernetes, which expects to see the public IP on the interface.
# In this script, we assign the public IP to the instance interface.

# TODO: Should this be in an Ansible playbook instead?

# NOTE: curl on CentOS 7 doesn't support fractional values for --max-time.
# NOTE: We use a max-time of 2 seconds since some API take some time to reply.
get() {
  curl --fail --max-time 2 --silent --show-error --header "Metadata-Flavor: Google" "$1"
}

dev="unknown"   # Interface name
intip="unknown" # Internal IP
pubip="unknown" # Public IP

# EC2
if get http://169.254.169.254/latest/meta-data >/dev/null; then
  echo "Amazon EC2 detected"
  intip=$(get http://169.254.169.254/latest/meta-data/local-ipv4)
  pubip=$(get http://169.254.169.254/latest/meta-data/public-ipv4)
fi

# GCP
if get http://metadata.google.internal/computeMetadata/v1/instance/ >/dev/null; then
  echo "Google Compute Engine detected"
  intip=$(get http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
  pubip=$(get http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
fi

# Scaleway
if get http://169.254.42.42/conf >/dev/null; then
  echo "Scaleway Compute detected"
  intip=$(get http://169.254.42.42/conf | grep PRIVATE_IP | cut -d = -f 2)
  pubip=$(get http://169.254.42.42/conf | grep PUBLIC_IP_ADDRESS | cut -d = -f 2)
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
echo "KUBELET_EXTRA_ARGS=--node-ip ${pubip}" | tee >/etc/default/kubelet
