#!/bin/sh

set -eu
export DEBIAN_FRONTEND=noninteractive

# For debugging/development, set this to "file://." or another local directory.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/edgenet.git}"
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node-full.yml}"

# Some systems do not have sudo, in this case do not use it.
SUDO="sudo"
if ! command -v "${SUDO}" >/dev/null 2>&1; then
    SUDO=""
fi

# Fetch the OS identifier.
ID="unknown"
. /etc/os-release

case ${ID} in
    centos)
        ${SUDO} yum install --assumeyes epel-release
        ${SUDO} yum install --assumeyes ansible git python3-pip
        ;;

    fedora)
        ${SUDO} dnf install --assumeyes ansible git python3-pip
        ;;

    debian)
        ${SUDO} apt update
        ${SUDO} apt install --yes dirmngr software-properties-common
        ${SUDO} apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        ${SUDO} apt-add-repository --update --yes \
            "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
        ${SUDO} apt install --yes ansible git python3-pip
        ;;

    ubuntu)
        ${SUDO} apt update
        ${SUDO} apt install --yes dirmngr software-properties-common
        ${SUDO} apt-add-repository --yes --update ppa:ansible/ansible
        ${SUDO} apt install --yes ansible git python3-pip
        ;;

    *)
        echo "Unsupported operating system: ${ID}"
        exit 1
        ;;
esac

# Fetch the repository.
TMP=$(mktemp -d)
git clone --depth 1 "${EDGENET_REPOSITORY}" "${TMP}"

# Install collections and roles from Ansible Galaxy.
ansible-galaxy collection install --ignore-errors --requirements-file "${TMP}/requirements.yml"
ansible-galaxy role install --ignore-errors --role-file "${TMP}/requirements.yml"

# Run the node playbook.
ansible-playbook --connection local \
                 --extra-vars "ansible_python_interpreter=/usr/bin/python3" \
                 --inventory "localhost," \
                 "${TMP}/${EDGENET_PLAYBOOK}"
