#!/bin/sh
set -eu

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/node.git}"

# Name of the playbook to run.
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node-full.yml}"

# Name to be used for the edgenet node.
EDGENET_NODE_NAME="${EDGENET_NODE_NAME:-$(cat /etc/machine-id)}"

# SSH port to be used for remote access.
EDGENET_SSH_PORT="${EDGENET_SSH_PORT:-25010}"

echo "EDGENET_REPOSITORY=${EDGENET_REPOSITORY}"
echo "EDGENET_PLAYBOOK=${EDGENET_PLAYBOOK}"
echo "EDGENET_NODE_NAME=${EDGENET_NODE_NAME}"
echo "EDGENET_SSH_PORT=${EDGENET_SSH_PORT}"

echo
echo "To change these values, set the appropriate environement variable."
echo "For example: 'env EDGENET_SSH_PORT=25010 bootstrap.sh'."
echo "Press any key to continue, or CTRL+C to exit..."
read -r _

# Do not use sudo if not installed.
SUDO=""
command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# Temporary directory for cloning the repository.
TMP=$(mktemp -d)

# OS-specific variables.
ID="Unknown"
VERSION_ID="Unknown"
. /etc/os-release

# Install Ansible.
case "${ID}-${VERSION_ID}" in
    centos-8)
        ${SUDO} yum install --assumeyes epel-release
        ${SUDO} yum install --assumeyes ansible git
        ;;

    fedora-32|fedora-33)
        ${SUDO} dnf install --assumeyes ansible git
        ;;

    ubuntu-18*|ubuntu-19*)
        export DEBIAN_FRONTEND=noninteractive
        ${SUDO} apt update
        ${SUDO} apt install --yes dirmngr software-properties-common
        ${SUDO} apt-add-repository --yes --update ppa:ansible/ansible
        ${SUDO} apt install --yes ansible git
        ;;

    ubuntu-20*|ubuntu-21*)
        export DEBIAN_FRONTEND=noninteractive
        ${SUDO} apt update
        ${SUDO} apt install --yes ansible git
        ;;

    *)
        echo "Unsupported operating system: ${ID}-${VERSION_ID}"
        exit 1
        ;;
esac

# Fetch the repository.
git clone --depth 1 "${EDGENET_REPOSITORY}" "${TMP}"

# Install collections and roles from Ansible Galaxy.
ansible-galaxy collection install --ignore-errors --requirements-file "${TMP}/requirements.yml"
ansible-galaxy role install --ignore-errors --role-file "${TMP}/requirements.yml"

# Run the node playbook.
ansible-playbook --connection local \
                 --extra-vars "ansible_python_interpreter=/usr/bin/python3" \
                 --extra-vars "edgenet_node_name=${EDGENET_NODE_NAME}" \
                 --extra-vars "edgenet_ssh_port=${EDGENET_SSH_PORT}" \
                 --inventory "localhost," \
                 "${TMP}/${EDGENET_PLAYBOOK}"
