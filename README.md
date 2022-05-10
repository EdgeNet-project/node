# EdgeNet Node Setup

[![Go Report Card](https://goreportcard.com/badge/github.com/EdgeNet-project/node)](https://goreportcard.com/report/github.com/EdgeNet-project/node)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/EdgeNet-project/node/Build?label=build)](https://github.com/EdgeNet-project/node/actions/workflows/build.yml)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/EdgeNet-project/node/CodeQL?label=codeql)](https://github.com/EdgeNet-project/node/actions/workflows/codeql-analysis.yml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/EdgeNet-project/node)](https://github.com/EdgeNet-project/node/releases)

📌 **For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://www.edge-net.org/pages/node-contribution.html).**

## Architecture

This repository contains the code necessary to automatically deploy an EdgeNet node.
It consists of three parts:
1. The [bootstrap script](#bootstrap-script) which installs Ansible and runs the node playbook with [ansible-pull](https://docs.ansible.com/ansible/latest/cli/ansible-pull.html).
2. The [Ansible roles](#ansible-roles), which setups SSH access, containerd, Kubernetes and the EdgeNet service.
3. The [EdgeNet service](#edgenet-service), which is run on every boot, via systemd, to configure the node hostname and network. It will also join the node to the cluster, if not already joined.

In most cases users will run the bootstrap script and wait until the node is ready.
However, it is also possible to run the node playbook directly on the target machines with [ansible-playbook](https://docs.ansible.com/ansible/latest/cli/ansible-playbook.html).

### Bootstrap script

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
It can be configured with the following environment variables:

Name                       | Default                                      | Description
:--------------------------|:---------------------------------------------|:-----------
`EDGENET_ASK_CONFIRMATION` | 1                                            | Whether to ask to continue or not.
`EDGENET_PLAYBOOK`         | [edgenet-node.yml](edgenet-node.yml)         | Name of the playbook to run.
`EDGENET_REF`              | main                                         | Git reference to use.
`EDGENET_REPOSITORY`       |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run.

### Ansible roles

#### [edgenet-ssh](/roles/edgenet-ssh)

Create an EdgeNet user with SSH access and passwordless sudo.

Variable                 | Default                            | Description
:------------------------|:-----------------------------------|:-----------
`edgenet_ssh_user`       | edgenet                            | EdgeNet SSH user
`edgenet_ssh_port_alt`   | 25010                              | Alternative SSH port if port 22 is unavailable
`edgenet_ssh_public_key` | [...] edgenet.planet-lab.eu (2021) | Public SSH key of the EdgeNet user

#### [edgenet-kubernetes](/roles/edgenet-kubernetes)

Setup Docker and Kubernetes.

Variable                 | Default   | Description
:------------------------|:----------|:-----------
`edgenet_service_state`  | restarted | State of the EdgeNet systemd service
`edgenet_node_version`   | -         | The [release](https://github.com/EdgeNet-project/node/releases) of the EdgeNet service to install
`containerd_version`     | -         | The containerd version to install
`kubernetes_version`     | -         | The kubernetes version to install

### EdgeNet service

The EdgeNet service is written in Go, in the [`main.go`](/main.go) file and the [`pkg/`](/pkg) directory.

## Development

#### Launch k8s cluster on AWS and deploy edgenet with local Ansible playbook
```bash
git clone -b aws.deployment git@github.com:atf828/node.git
cd node

# In case of providing an config file for terraform by user, run it in this way:
env EDGENET_REF="$(git rev-parse HEAD)" EDGENET_REPOSITORY="file://$(pwd)" AWS_VM_CONFIG="<path/filename of your local tfvars file>" ./bootstrap.aws.local.sh
# e.g. env EDGENET_REF="$(git rev-parse HEAD)" EDGENET_REPOSITORY="file://$(pwd)" AWS_VM_CONFIG="/tmp/test/my.tfvars" ./bootstrap.aws.local.sh

# In case of using default dev.tfvars file, run it in this way:
env EDGENET_REF="$(git rev-parse HEAD)" EDGENET_REPOSITORY="file://$(pwd)"  ./bootstrap.aws.local.sh
```
For the standard of the configuration file for terraform, please refer to:
https://github.com/atf828/node/blob/aws.deployment/tests/aws.cluster/terraform/dev.tfvars

#### Launch k8s cluster on AWS and deploy edgenet with git branch
```bash
# In case of providing an config file for terraform by user, run it in this way:
export AWS_VM_CONFIG="/tmp/test/my.tfvars"
bash -ci "$(wget -O - https://raw.githubusercontent.com/atf828/node/aws.deployment/bootstrap.aws.sh)"

# In case of using default dev.tfvars file, run it in this way:
bash -ci "$(wget -O - https://raw.githubusercontent.com/atf828/node/aws.deployment/bootstrap.aws.sh)"
```
#### Run the local bootstrap script with the local Ansible playbook

```bash
git clone git@github.com:EdgeNet-project/node.git
env EDGENET_REF="$(git rev-parse HEAD)" EDGENET_REPOSITORY="file://$(pwd)" ./bootstrap.sh
```

#### Use the Ansible playbook from a specific branch

```bash
export EDGENET_REF=my-branch
bash -ci "$(wget -O - https://raw.githubusercontent.com/EdgeNet-project/node/main/bootstrap.sh)"
```

#### Update the node binary

1. Create a GitHub release and wait for the completion of the associated workflow
2. Update `edgenet_node_version` in [vars/edgenet-production.yml](https://github.com/EdgeNet-project/node/blob/main/vars/edgenet-production.yml)

Alternatively, for debugging, you can compile the node binary locally and directly upload it to `/opt/edgenet/node` on the remote node.

## Cluster-wide play

To run a playbook across all the nodes of the cluster:
```bash
kubectl get nodes -l node-role.kubernetes.io/control-plane!= -o json | jq -r '.items[].status.addresses[0].address' > nodes.ini
ansible-playbook -i nodes.ini ...
```

## Contributing

The EdgeNet software is free and open source, licensed under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0); we invite you to contribute.
For more information, see [EdgeNet-project/edgenet](https://github.com/EdgeNet-project/edgenet#contributing).
