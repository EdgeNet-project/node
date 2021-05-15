#!/bin/bash
# shellcheck disable=SC2086
# vim: et sw=2 ts=2
set -eu

# To override one of these settings, set the appropriate environment variable.
# For example: `export EDGENET_ASK_CONFIRMATION=0`.

# Whether to ask to continue or not.
EDGENET_ASK_CONFIRMATION="${EDGENET_ASK_CONFIRMATION:-1}"

# Which branch of the node repository to use.
EDGENET_BRANCH="${EDGENET_BRANCH:-main}"

# URL of the cluster public kubeconfig file.
EDGENET_KUBECONFIG="${EDGENET_KUBECONFIG:-https://raw.githubusercontent.com/EdgeNet-project/edgenet/master/configs/public.cfg}"

# Name of the playbook to run.
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node.yml}"

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/node.git}"

# If the shell is non-interactive, do not ask for confirmation.
# See https://www.gnu.org/software/bash/manual/html_node/Is-this-Shell-Interactive_003f.html.
case "$-" in
  *i*) ;;
  *) EDGENET_ASK_CONFIRMATION=0 ;;
esac

echo -e "\033[1mWelcome to EdgeNet! (https://edge-net.org/)\033[0m"
echo -e "This script will install Ansible, and download and run the EdgeNet node playbook."
echo -e "In case of problem, contact \033[1medgenet-support@planet-lab.eu\033[0m."
echo
echo -e "\033[1mPress Enter to continue, or CTRL+C to exit...\033[0m"
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

if [ -f /etc/os-release ]; then
  . /etc/os-release
fi

# Run sudo once to avoid asking for the password later.
${SUDO} true

# Install Ansible and git if not present.
if is_not_installed ansible || is_not_installed git; then
  echo "Installing Ansible..."
  case "${ID}-${VERSION_ID}" in
  centos-7 | centos-8)
    ${SUDO} yum install --assumeyes --quiet epel-release
    ${SUDO} yum install --assumeyes --quiet ansible git
    ;;

  fedora-32 | fedora-33)
    ${SUDO} dnf install --assumeyes --quiet ansible git
    ;;

  ubuntu-18* | ubuntu-19*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes dirmngr software-properties-common
    ${SUDO} apt-add-repository --yes --update ppa:ansible/ansible
    ${SUDO} apt install --quiet --yes ansible git
    ;;

  ubuntu-20* | ubuntu-21*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes ansible git
    ;;

  *)
    echo "Unsupported operating system: ${ID}-${VERSION_ID}"
    exit 1
    ;;
  esac
fi

# CentOS 7 has old versions of Ansible/Git/Python,
# so we adjust the parameters in consequence.
case "${ID}-${VERSION_ID}" in
centos-7)
  PYTHON="/usr/bin/python2" ;;

*)
  PYTHON="/usr/bin/python3" ;;
esac

# Fetch the repository.
if [ "${EDGENET_REPOSITORY}" != "." ]; then
  LOCAL_REPOSITORY=$(mktemp -d)
  echo "Cloning ${EDGENET_REPOSITORY} to ${LOCAL_REPOSITORY}..."
  git clone --depth 1 --quiet --single-branch --branch "${EDGENET_BRANCH}" \
    "${EDGENET_REPOSITORY}" "${LOCAL_REPOSITORY}"
else
  LOCAL_REPOSITORY="${EDGENET_REPOSITORY}"
fi

# Run the node playbook.
export ANSIBLE_COLLECTIONS_PATHS="${LOCAL_REPOSITORY}"
ansible-playbook --connection local \
  --extra-vars "ansible_python_interpreter=${PYTHON}" \
  --extra-vars "edgenet_kubeconfig_url=${EDGENET_KUBECONFIG}" \
  --inventory "localhost," \
  "${LOCAL_REPOSITORY}/${EDGENET_PLAYBOOK}"
