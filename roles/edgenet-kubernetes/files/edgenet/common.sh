# shellcheck shell=sh
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

# NOTE: curl on CentOS 7 doesn't support fractional values for --max-time.
# NOTE: We use a max-time of 2 seconds since some APIs take some time to reply.
get() {
  curl --ipv4 --fail --max-time 2 --noproxy --silent --show-error \
    --header "Metadata: true" \
    --header "Metadata-Flavor: Google" \
    "$1"
}

# Query Azure instance metadata
az() {
  get "http://169.254.169.254/metadata/instance/${1-}?api-version=2020-09-01&format=text"
}

# Query AWS EC2 instance metadata
aws() {
  get "http://169.254.169.254/latest/meta-data/${1-}"
}

# Query Google Cloud Compute instance metadata
gcp() {
  get "http://metadata.google.internal/computeMetadata/v1/instance/${1-}"
}

# Query Scaleway instance metadata
scw() {
  res=$(get http://169.254.42.42/conf)
  status=$?
  if [ $status -eq 0 ]; then
    echo "${res}" | grep "${1-}" | cut --delimiter '=' --fields 2
  fi
  return $status
}

# Check if the machine is an Intel NUC
nuc() {
  dmidecode -s system-family | grep -i "Intel NUC"
}

# Return the country and the region inferred from the IP address
geoip() {
  resp=$(get "https://freegeoip.app/csv/")
  country=$(echo "${resp}" | cut --delimiter ',' --fields 2)
  region=$(echo "${resp}"  | cut --delimiter ',' --fields 4)
  region=${region:-${country}}
  echo "${country}-${region}"| tr '[:upper:]' '[:lower:]'
}

# Return the public IP address as seen from the Internet
pubip() {
  get "https://freegeoip.app/csv/" | cut --delimiter ',' --fields 1
}

# Generate a random string containing chars $1 with length $2.
# Example: rand 'a-f0-9' 4
rand() {
  dd bs=512 count=1 if=/dev/urandom | tr --complement --delete "$1" | fold --width "$2" | head --lines 1
}
