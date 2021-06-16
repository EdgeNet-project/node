#!/bin/sh
# vim: et sw=2 ts=2

# Copyright 2021 Contributors to the EdgeNet project
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
