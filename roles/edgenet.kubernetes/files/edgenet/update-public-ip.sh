#!/bin/sh
set -ux

# On some cloud providers, instances with a public IP are behind a NAT.
# The instances have a private IP on their interface, and the gateway
# replace it with the public IP.
# We assign the public IP to the internal interface, as required by kubelet.

# NOTE: curl on CentOS 7 doesn't support fractional values for --max-time.
get() {
  curl --fail --max-time 1 --silent --show-error --header "Metadata-Flavor: Google" "$1"
}

# EC2
if get http://169.254.169.254/latest/meta-data >/dev/null; then
  echo "Amazon EC2 detected"
  mac=$(get http://169.254.169.254/latest/meta-data/mac)
  ip4=$(get http://169.254.169.254/latest/meta-data/public-ipv4)
  dev=$(ip --brief link | grep "${mac}" | cut -d ' ' -f 1)
  ip addr add "${ip4}/32" dev "${dev}" || true
  echo "KUBELET_EXTRA_ARGS=--node-ip ${ip4}" | tee >/etc/default/kubelet
  exit
fi

# GCP
if get http://metadata.google.internal/computeMetadata/v1/instance/ >/dev/null; then
  echo "Google Compute Engine detected"
  mac=$(get http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/mac)
  ip4=$(get http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  dev=$(ip --brief link | grep "${mac}" | cut -d ' ' -f 1)
  ip addr add "${ip4}/32" dev "${dev}" || true
  echo "KUBELET_EXTRA_ARGS=--node-ip ${ip4}" | tee >/etc/default/kubelet
  exit
fi
