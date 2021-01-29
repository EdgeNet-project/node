#!/bin/bash
set -eu

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/node.git}"

# Whether to clone or not the Git repository (useful for local development).
EDGENET_REPOSITORY_CLONE="${EDGENET_REPOSITORY_CLONE:-1}"

# Name of the playbook to run.
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node-full.yml}"

# Name to be used for the edgenet node.
EDGENET_NODE_NAME="${EDGENET_NODE_NAME:-$(cat /etc/machine-id)}"

# SSH port to be used for remote access.
EDGENET_SSH_PORT="${EDGENET_SSH_PORT:-25010}"

# Whether to ask to continue or not.
EDGENET_ASK_CONFIRMATION="${EDGENET_ASK_CONFIRMATION:-1}"

echo -e "\033[1mWelcome to EdgeNet!\033[0m"
echo "Project homepage: https://edge-net.org/"
echo "Node setup instructions: https://github.com/EdgeNet-project/node/"
echo

echo "EDGENET_REPOSITORY=${EDGENET_REPOSITORY}"
echo "EDGENET_REPOSITORY_CLONE=${EDGENET_REPOSITORY_CLONE}"
echo "EDGENET_PLAYBOOK=${EDGENET_PLAYBOOK}"
echo "EDGENET_NODE_NAME=${EDGENET_NODE_NAME}"
echo "EDGENET_SSH_PORT=${EDGENET_SSH_PORT}"
echo "EDGENET_ASK_CONFIRMATION=${EDGENET_ASK_CONFIRMATION}"

echo
echo "To change these values, set the appropriate environement variable."
echo "For example: 'export EDGENET_SSH_PORT=25010'."
echo "Press any key to continue, or CTRL+C to exit..."
[ "${EDGENET_ASK_CONFIRMATION}" -eq 1 ] && read -r _

is_not_installed() {
    ! command -v "$1" >/dev/null 2>&1
}

# Do not use sudo if not installed.
SUDO="sudo"
is_not_installed sudo && SUDO=""

# OS-specific variables.
ID="Unknown"
VERSION_ID="Unknown"
. /etc/os-release

# Install Ansible and git if not present.
if is_not_installed ansible || is_not_installed git; then
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
fi

# Fetch the repository.
if [ "${EDGENET_REPOSITORY_CLONE}" -eq 1 ]; then
    LOCAL_REPOSITORY=$(mktemp -d)
    git clone --depth 1 --recursive "${EDGENET_REPOSITORY}" "${LOCAL_REPOSITORY}"
else
    LOCAL_REPOSITORY="${EDGENET_REPOSITORY}"
fi

# Run the node playbook.
export ANSIBLE_COLLECTIONS_PATHS="${LOCAL_REPOSITORY}"
ansible-playbook --connection local \
                 --extra-vars "ansible_python_interpreter=/usr/bin/python3" \
                 --extra-vars "edgenet_node_name=${EDGENET_NODE_NAME}" \
                 --extra-vars "edgenet_ssh_port=${EDGENET_SSH_PORT}" \
                 --inventory "localhost," \
                 "${LOCAL_REPOSITORY}/${EDGENET_PLAYBOOK}"
