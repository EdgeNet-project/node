<p align="center">
  <img src="/assets/edgenet_logo_2020_05_03_w_text_075dpi.png" height="130"><br/><br/>
  <i>The globally distributed edge cloud for Internet researchers.</i>
</p>

## :cloud: Contribute an EdgeNet node

For instructions on how to use and how to contribute a node to EdgeNet, please see the [EdgeNet website](https://edgenet-project.github.io/).

## Bootstrap script

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
The script can be configured with the following environment variables:

Name | Default | Description
-----|---------|------------
`EDGENET_REPOSITORY` |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run.
`EDGENET_REPOSITORY_CLONE` | 1 | Whether to clone or not the Git repository (useful for local development).
`EDGENET_PLAYBOOK` | edgenet-node-full.yml | Name of the playbook to run.
`EDGENET_NODE_NAME` | `$(cat /etc/machine-id)` | Name to be used for the EdgeNet node.
`EDGENET_SSH_PORT_ALT` | 25010 | Alternative SSH port to be used for remote access.
`EDGENET_ASK_CONFIRMATION` | 1 | Whether to ask to continue or not.

## Ansible roles

This repository contains the following Ansible roles:

Name | Description | Variables | Defaults
-----|-------------|-----------|---------
[edgenet.ssh](/roles/edgenet.ssh) | Create an EdgeNet user with SSH access and passwordless sudo | `edgenet_ssh_user`, `edgenet_ssh_port_alt`, `edgenet_ssh_public_key` | [main.yml](/roles/edgenet.ssh/defaults/main.yml)
[edgenet.kubernetes](/roles/edgenet.kubernetes) | Setup Docker and Kubernetes | `edgenet_node_name`, `edgenet_node_namespace`, `edgenet_docker_version`, `edgenet_kubernetes_version` | None

## Development

```bash
git clone --recursive git@github.com:EdgeNet-project/node.git
export EDGENET_REPOSITORY=. EDGENET_REPOSITORY_CLONE=0
./bootstrap.sh
```

## TODO

- [ ] Fix install of public SSH key on Google Cloud (use API/instance metadata)
- [ ] Auto-naming of the nodes? edge-net-gcp-...?
- [ ] Pass token for existing users.
- [ ] Asciinema
