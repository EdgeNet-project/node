#!/bin/sh
set -ux

# Assign public IPs to internal interfaces.
# Major public clouds rewrite the src/dst IP of outbound/inbound packets.

alias curl="curl --max-time 0.5 --show-error --silent --header 'Metadata-Flavor: Google'"

# EC2
if curl http://169.254.169.254/latest/meta-data > /dev/null; then
  echo "Amazon EC2 detected"
  mac=$(curl http://169.254.169.254/latest/meta-data/mac)
  ip4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
  dev=$(ip --brief link | grep "${mac}" | cut -d ' ' -f 1)
  ip addr add "${ip4}/32" dev "${dev}" || true
  exit
fi

# GCP
if curl http://metadata.google.internal/computeMetadata/v1/instance/ > /dev/null; then
  echo "Google Compute Engine detected"
  mac=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/mac)
  ip4=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
  dev=$(ip --brief link | grep "${mac}" | cut -d ' ' -f 1)
  ip addr add "${ip4}/32" dev "${dev}" || true
  exit
fi
