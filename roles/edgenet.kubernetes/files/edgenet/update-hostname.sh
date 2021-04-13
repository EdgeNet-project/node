#!/bin/sh
# vim: et sw=2 ts=2
set -eux

. /opt/edgenet/common.sh

# Generate a hostname if not set
if [ ! -f /opt/edgenet/hostname ]; then
  hash=$(rand 'a-f0-9' 4)

  if az >/dev/null; then
    region=$(az compute/location)
    hostname="az-${region}-${hash}"
  elif aws >/dev/null; then
    region=$(aws placement/availability-zone)
    hostname="aws-${region}-${hash}"
  elif gcp >/dev/null; then
    region=$(gcp zone | cut --delimiter '/' --field 4)
    hostname="gcp-${region}-${hash}"
  elif scw >/dev/null; then
    region=$(scw LOCATION_ZONE_ID)
    hostname="scw-${region}-${hash}"
  elif nuc >/dev/null; then
    hostname="nuc-$(geoip)-${hash}"
  else
    hostname="$(geoip)-${hash}"
  fi

  echo "${hostname}.edge-net.io" > /opt/edgenet/hostname
fi

# Read the saved hostname
hostname=$(cat /opt/edgenet/hostname)

# Update /etc/hostname
hostnamectl set-hostname "${hostname}"

# Update /etc/hosts
sed -i.bak '/.edge-net.io$/d' /etc/hosts
echo "127.0.0.1 ${hostname}" | tee -a /etc/hosts
