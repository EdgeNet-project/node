#!/bin/bash
# shellcheck disable=SC2086
# vim: et sw=2 ts=2
set -eu

# Whether to ask to continue or not.
EDGENET_ASK_CONFIRMATION="${EDGENET_ASK_CONFIRMATION:-1}"

# Name of the playbook to run.
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node-full.yml}"

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/EdgeNet-project/node.git}"

# Whether to start or not the EdgeNet service (useful for Cloud/VM images).
EDGENET_SERVICE_START="${EDGENET_SERVICE_START:-1}"

echo -e "\033[1mWelcome to EdgeNet!\033[0m"
echo -e "\033[1mhttps://edge-net.org/\033[0m"
echo

echo "EDGENET_ASK_CONFIRMATION=${EDGENET_ASK_CONFIRMATION}"
echo "EDGENET_PLAYBOOK=${EDGENET_PLAYBOOK}"
echo "EDGENET_REPOSITORY=${EDGENET_REPOSITORY}"
echo "EDGENET_SERVICE_START=${EDGENET_SERVICE_START}"

echo
echo "To change these values, set the appropriate environement variable."
echo "For example: 'export EDGENET_ASK_CONFIRMATION=0'."
echo -e "\033[1mPress any key to continue, or CTRL+C to exit...\033[0m"
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
  GIT_EXTRA_OPTS=""
  PYTHON="/usr/bin/python2"
  ;;

*)
  GIT_EXTRA_OPTS="--jobs 4 --shallow-submodules"
  PYTHON="/usr/bin/python3"
  ;;
esac

# Fetch the repository.
if [ "${EDGENET_REPOSITORY}" != "." ]; then
  LOCAL_REPOSITORY=$(mktemp -d)
  echo "Cloning ${EDGENET_REPOSITORY} to ${LOCAL_REPOSITORY}..."
  git clone --depth 1 --quiet --recursive ${GIT_EXTRA_OPTS} \
    "${EDGENET_REPOSITORY}" "${LOCAL_REPOSITORY}"
else
  LOCAL_REPOSITORY="${EDGENET_REPOSITORY}"
fi

# Populate the `edgenet_service_state` variable.
edgenet_service_state="stopped"
if [ "${EDGENET_SERVICE_START}" -eq 1 ]; then
  edgenet_service_state="restarted"
fi

# Run the node playbook.
export ANSIBLE_COLLECTIONS_PATHS="${LOCAL_REPOSITORY}"
ansible-playbook --connection local \
  --extra-vars "ansible_python_interpreter=${PYTHON}" \
  --extra-vars "edgenet_service_state=${edgenet_service_state}" \
  --inventory "localhost," \
  "${LOCAL_REPOSITORY}/${EDGENET_PLAYBOOK}"
