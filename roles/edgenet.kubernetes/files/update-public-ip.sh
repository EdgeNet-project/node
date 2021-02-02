#!/bin/sh
set -ux

# Assign public IPs to internal interfaces.
# Major public clouds rewrite the src/dst IP of outbound/inbound packets.

# EC2
if curl --max-time 0.5 --show-error --silent http://169.254.169.254/latest/meta-data > /dev/null; then
  echo "Amazon EC2 detected"
  mac=$(curl --show-error --silent http://169.254.169.254/latest/meta-data/mac)
  ip4=$(curl --show-error --silent http://169.254.169.254/latest/meta-data/public-ipv4)
  dev=$(ip --brief link | grep "${mac}" | cut -d ' ' -f 1)
  ip addr add "${ip4}/32" dev "${dev}" || true
fi

# GCP
# TODO

