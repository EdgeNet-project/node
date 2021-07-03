# EdgeNet Node Setup

[![Build](https://github.com/EdgeNet-project/node/actions/workflows/build.yml/badge.svg)](https://github.com/EdgeNet-project/node/actions/workflows/build.yml)

**For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://edgenet-project.github.io/).**

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

## Contributing

The EdgeNet software is free and open source, licensed under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0); we invite you to contribute.
For more information, see [EdgeNet-project/edgenet](https://github.com/EdgeNet-project/edgenet#contributing).
