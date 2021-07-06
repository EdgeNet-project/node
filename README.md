# EdgeNet Node Setup

[![Go Report Card](https://goreportcard.com/badge/github.com/EdgeNet-project/node)](https://goreportcard.com/report/github.com/EdgeNet-project/node)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/EdgeNet-project/node/Build?logo=github&logoColor=white)](https://github.com/EdgeNet-project/node/actions/workflows/build.yml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/EdgeNet-project/node?logo=github&logoColor=white)](https://github.com/EdgeNet-project/node/releases)

📌 **For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://www.edge-net.org/pages/node-contribution.html).**

## Architecture

The automated procedure for the deployment of a new EdgeNet node consists of three parts:
1. The [bootstrap script](#bootstrap-script) which installs Ansible and runs the node playbook with `ansible-pull`.
2. The [Ansible roles](#ansible-roles), which setups SSH access, containerd, Kubernetes and the EdgeNet service.
3. The [EdgeNet service](#edgenet-service), which is run on every boot, via `systemd`, to configure the node hostname and network. It will also join the node to the cluster, if not already joined.

For specific use-cases, the bootstrap script can be skipped, and the node playbook can be applied directly on the target machines with `ansible-playbook`.

### Bootstrap script

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
The script can be configured with the following environment variables:

Name | Default | Description
-----|---------|------------
`EDGENET_ASK_CONFIRMATION` | 1 | Whether to ask to continue or not.
`EDGENET_PLAYBOOK` | [edgenet-node.yml](edgenet-node.yml) | Name of the playbook to run.
`EDGENET_REF` | main | Git reference to use.
`EDGENET_REPOSITORY` |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run.

### Ansible roles

This repository contains the following Ansible roles:

Name | Description | Variables | Defaults
-----|-------------|-----------|---------
[edgenet-ssh](/roles/edgenet-ssh) | Create an EdgeNet user with SSH access and passwordless sudo | `edgenet_ssh_user`, `edgenet_ssh_port_alt`, `edgenet_ssh_public_key` | [main.yml](/roles/edgenet.ssh/defaults/main.yml)
[edgenet-kubernetes](/roles/edgenet-kubernetes) | Setup Docker and Kubernetes | `edgenet_service_state`, `containerd_version`, `kubernetes_version` | [main.yml](/roles/edgenet-kubernetes/defaults/main.yml)

### EdgeNet service

The EdgeNet service is written in Go, in the [`main.go`](/main.go) file and the [`pkg/`](/pkg) directory.

## Development

```bash
git clone git@github.com:EdgeNet-project/node.git
env EDGENET_REF="$(git rev-parse HEAD)" EDGENET_REPOSITORY="file://$(pwd)" ./bootstrap.sh
```

## Cluster-wide play

To run a playbook across all the nodes of the cluster:
```bash
kubectl get nodes -l node-role.kubernetes.io/control-plane!= -o json | jq -r '.items[].status.addresses[0].address' > nodes.ini
ansible-playbook -i nodes.ini ...
```

## Contributing

The EdgeNet software is free and open source, licensed under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0); we invite you to contribute.
For more information, see [EdgeNet-project/edgenet](https://github.com/EdgeNet-project/edgenet#contributing).
