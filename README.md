<p align="center">
  <img src="https://github.com/EdgeNet-project/edgenet/blob/master/assets/logos/edgenet_logos_2020_05_03/edgenet_logo_2020_05_03_w_text_075dpi.png" height="130"><br/><br/>
  <i>The globally distributed edge cloud for Internet researchers.</i>
</p>

## :cloud: Contribute an EdgeNet node

For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://edgenet-project.github.io/).

## Bootstrap script

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
The script can be configured with the following environment variables:

Name | Default | Description
-----|---------|------------
`EDGENET_ASK_CONFIRMATION` | 1 | Whether to ask to continue or not.
`EDGENET_PLAYBOOK` | edgenet-node-full.yml | Name of the playbook to run.
`EDGENET_REPOSITORY` |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run. Set to `.` to use the current directory (useful for local development).
`EDGENET_SERVICE_START` | 1 | Whether to start or not the EdgeNet service (useful for Cloud/VM images).

## Ansible roles

This repository contains the following Ansible roles:

Name | Description | Variables | Defaults
-----|-------------|-----------|---------
[edgenet.ssh](/roles/edgenet.ssh) | Create an EdgeNet user with SSH access and passwordless sudo | `edgenet_ssh_user`, `edgenet_ssh_port_alt`, `edgenet_ssh_public_key` | [main.yml](/roles/edgenet.ssh/defaults/main.yml)
[edgenet.kubernetes](/roles/edgenet.kubernetes) | Setup Docker and Kubernetes | `edgenet_service_state`, `edgenet_docker_version`, `edgenet_kubernetes_version` | None

## Development

```bash
git clone --recursive git@github.com:EdgeNet-project/node.git
env EDGENET_REPOSITORY=. ./bootstrap.sh
```
