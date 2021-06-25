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

hostname=$(cat /opt/edgenet/hostname)
kubeconfig=/opt/edgenet/public.cfg
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
apiVersion: core.edgenet.io/v1alpha
kind: NodeContribution
metadata:
  name: ${hostname%.edge-net.io}
spec:
  host: ${pubip}
  port: 22
  user: edgenet
  enabled: true
EOF

  cat "${nodecontribution}"
  kubectl --kubeconfig "${kubeconfig}" create --filename "${nodecontribution}"
fi
