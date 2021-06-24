# EdgeNet Node Setup

[![Tests](https://github.com/EdgeNet-project/node/actions/workflows/tests.yml/badge.svg)](https://github.com/EdgeNet-project/node/actions/workflows/tests.yml)

**For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://edgenet-project.github.io/).**

## Bootstrap script

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
The script can be configured with the following environment variables:

Name | Default | Description
-----|---------|------------
`EDGENET_ASK_CONFIRMATION` | 1 | Whether to ask to continue or not.
`EDGENET_PLAYBOOK` | [edgenet-node.yml](edgenet-node.yml) | Name of the playbook to run.
`EDGENET_REPOSITORY` |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run. Set to `.` to use the current directory (useful for local development).

## Ansible roles

This repository contains the following Ansible roles:

Name | Description | Variables | Defaults
-----|-------------|-----------|---------
[edgenet-ssh](/roles/edgenet-ssh) | Create an EdgeNet user with SSH access and passwordless sudo | `edgenet_ssh_user`, `edgenet_ssh_port_alt`, `edgenet_ssh_public_key` | [main.yml](/roles/edgenet.ssh/defaults/main.yml)
[edgenet-kubernetes](/roles/edgenet-kubernetes) | Setup Docker and Kubernetes | `edgenet_service_state`, `containerd_version`, `kubernetes_version` | [main.yml](/roles/edgenet-kubernetes/defaults/main.yml)

## Development

```bash
git clone --recursive git@github.com:EdgeNet-project/node.git
env EDGENET_REPOSITORY=. ./bootstrap.sh
```

## Contributing

The EdgeNet software is free and open source, licensed under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0); we invite you to contribute.  
For more information, see [EdgeNet-project/edgenet](https://github.com/EdgeNet-project/edgenet#contributing).
