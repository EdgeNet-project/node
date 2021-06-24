#!/bin/bash
# shellcheck disable=SC2086
# vim: et sw=2 ts=2

# Copyright 2021 Contributors to the EdgeNet project
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

# To override one of these settings, set the appropriate environment variable.
# For example: `export EDGENET_ASK_CONFIRMATION=0`.

# Whether to ask to continue or not.
EDGENET_ASK_CONFIRMATION="${EDGENET_ASK_CONFIRMATION:-1}"

# Name of the playbook to run.
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node.yml}"

# Which branch of the node repository to use.
EDGENET_REF="${EDGENET_REF:-main}"

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
  centos-*)
    ${SUDO} yum install --assumeyes --quiet epel-release
    ${SUDO} yum install --assumeyes --quiet ansible git
    ;;

  fedora-*)
    ${SUDO} dnf install --assumeyes --quiet ansible git
    ;;

  ubuntu-1*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes dirmngr software-properties-common
    ${SUDO} apt-add-repository --yes --update ppa:ansible/ansible
    ${SUDO} apt install --quiet --yes ansible git
    ;;

  ubuntu-2*)
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

# Run the node playbook.
ansible-pull --accept-host-key --extra-vars "ansible_python_interpreter=${PYTHON}" \
  --checkout "${EDGENET_REF}" --url "${EDGENET_REPOSITORY}" "${EDGENET_PLAYBOOK}"
