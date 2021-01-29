<p align="center">
  <img src="/assets/edgenet_logo_2020_05_03_w_text_075dpi.png" height="130"><br/><br/>
  <i>The globally distributed edge cloud for Internet researchers.</i>
</p>

## Contribute an EdgeNet node

### From a dedicated machine

If you want to dedicate a physical (e.g. a Raspberry Pi) or a virtual machine to the EdgeNet project,
ensure that the machine has a public IP address and run the following command on the target machine:
```bash
bash -c "$(wget -O - https://edge-net.org/bootstrap.sh)"
```

Supported operating systems: CentOS 8+, Fedora 32+, Ubuntu 18.04+.
See [Bootstrap](#Bootstrap) for more information.

### In the cloud

We have pre-built images for the major cloud providers.
Simply run one of the following to deploy a node:
```bash
az vm create ...
aws create-instance ...
gcloud compute instances create ...
```

## Bootstrap

The [`bootstrap.sh`](/bootstrap.sh) script installs Ansible and Git, and runs the node playbook.
The script can be configured with the following environment variables:

Name | Default | Description
-----|---------|------------
`EDGENET_REPOSITORY` |  https://github.com/EdgeNet-project/node.git | URL of the Git repository containing the playbook to run.
`EDGENET_REPOSITORY_CLONE` | 1 | Whether to clone or not the Git repository (useful for local development).
`EDGENET_PLAYBOOK` | edgenet-node-full.yml | Name of the playbook to run.
`EDGENET_NODE_NAME` | `$(cat /etc/machine-id)` | Name to be used for the EdgeNet node.
`EDGENET_SSH_PORT` | 25010 | SSH port to be used for remote access.
`EDGENET_ASK_CONFIRMATION` | 1 | Whether to ask to continue or not.

## Roles

This repository contains the following Ansible roles:

Name | Description | Variables | Defaults
-----|-------------|-----------|---------
[edgenet.ssh](/roles/edgenet.ssh) | Create an EdgeNet user with SSH access and passwordless sudo | `edgenet_ssh_user`, `edgenet_ssh_port`, `edgenet_ssh_public_key` | [main.yml](/roles/edgenet.ssh/defaults/main.yml)
[edgenet.kubernetes](/roles/edgenet.kubernetes) | Setup Docker and Kubernetes | `edgenet_node_name`, `edgenet_node_namespace`, `edgenet_docker_version`, `edgenet_kubernetes_version` | [main.yml](/roles/edgenet.kubernetes/defaults/main.yml)

## Development

```bash
# To test the boostrap script locally, for example:
export EDGENET_REPOSITORY=$(pwd)
export EDGENET_REPOSITORY_CLONE=0
./bootstrap.sh
```

## TODO

Call in bootstrap to EdgeNet ctrl to create the NC object, which creates the DNS entry, and calls back the playbook with the join token.
Add the node name to the shell script.
Pass token for existing users.

- [ ] Packer
- [ ] Asciinema
- [ ] Squash commits
