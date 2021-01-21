#!/bin/sh
set -eu

# For debugging/development, set this to "file://." or another local directory.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/node.git}"
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node-full.yml}"

# Some systems do not have sudo, in this case do not use it.
SUDO=""
command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# OS-specific variables.
ID="Unknown"
VERSION_ID="Unknown"
. /etc/os-release

case "${ID}-${VERSION_ID}" in
    centos-8)
        ${SUDO} yum install --assumeyes epel-release
        ${SUDO} yum install --assumeyes ansible git python3-openshift
        ;;

    fedora-32|fedora-33)
        ${SUDO} dnf install --assumeyes ansible git python3-openshift
        ;;

    debian-9)
        export DEBIAN_FRONTEND=noninteractive
        ${SUDO} apt update
        ${SUDO} apt install --yes dirmngr software-properties-common
        ${SUDO} apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        ${SUDO} apt-add-repository --update --yes \
            "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
        ${SUDO} apt install --yes ansible git python3-pip
        ;;

    ubuntu-18*|ubuntu-19*|ubuntu-20*|ubuntu-21*)
        export DEBIAN_FRONTEND=noninteractive
        ${SUDO} apt update
        ${SUDO} apt install --yes dirmngr software-properties-common
        ${SUDO} apt-add-repository --yes --update ppa:ansible/ansible
        ${SUDO} apt install --yes ansible git python3-pip
        ;;

    *)
        echo "Unsupported operating system: ${ID}-${VERSION_ID}"
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
