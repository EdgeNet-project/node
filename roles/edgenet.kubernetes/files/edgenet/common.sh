# shellcheck shell=sh
# vim: et sw=2 ts=2

# NOTE: curl on CentOS 7 doesn't support fractional values for --max-time.
# NOTE: We use a max-time of 2 seconds since some API take some time to reply.
get() {
  curl --ipv4 --fail --max-time 2 --noproxy --silent --show-error \
    --header "Metadata: true" \
    --header "Metadata-Flavor: Google" \
    "$1"
}

# Query Azure instance metadata
az() {
  get "http://169.254.169.254/metadata/instance"
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
  get http://169.254.42.42/conf | grep "${1-}" | cut --delimiter '=' --fields 2
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
  tr --complement --delete "$1" < /dev/urandom | fold --width "$2" | head --lines 1
}
