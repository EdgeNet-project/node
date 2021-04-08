#!/bin/sh
# vim: et sw=2 ts=2
set -eux

. /opt/edgenet/common.sh

hostname=$(cat /opt/edgenet/hostname)
kubeconfig_url=$(cat /opt/edgenet/public.cfg)
pubip=$(pubip)

for cmd in kubeadm kubectl kubelet; do
  if ! command -v "${cmd}" >/dev/null; then
    echo "${cmd} is not installed."
    exit 1
  fi
done

if [ ! -f /var/lib/kubelet/config.yaml ]; then
  nodecontribution=$(mktemp)
  cat << EOF > "${nodecontribution}"
apiVersion: apps.edgenet.io/v1alpha
kind: NodeContribution
metadata:
  name: ${hostname%.edge-net.io}
  namespace: authority-edgenet
spec:
  host: ${pubip}
  port: 22
  user: edgenet
  enabled: true
EOF

  cat "${nodecontribution}"
  kubectl --kubeconfig "${kubeconfig}" create --filename "${nodecontribution}"
fi
