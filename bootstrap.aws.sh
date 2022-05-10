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
# EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-node.yml}"
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-aws-cluster.yml}"

# Which branch of the node repository to use.
EDGENET_REF="${EDGENET_REF:-aws.deployment}"

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/atf828/node.git}"

# Configure of aws instances to be used by Terraform, the default value will be created by later process
AWS_VM_CONFIG="${AWS_VM_CONFIG:-/tmp/aws-test/dev.tfvars}"

# Host of remoote servers to be used by Ansible, the default value will be created by later process
HOST_FILE="${HOST_FILE:-/tmp/aws-test/hosts}"


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

# Install ansible and git if not present.
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


# Install terraform in not present
if is_not_installed terraform; then
echo "Installing Terraform..."
  case "${ID}-${VERSION_ID}" in
  centos-*)
    ${SUDO} yum install --assumeyes --quiet epel-release
    ${SUDO} yum install --assumeyes --quiet terraform
    ;;

  fedora-*)
    ${SUDO} dnf install --assumeyes --quiet terraform
    ;;

  ubuntu-1*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes dirmngr software-properties-common
    ${SUDO} apt-add-repository --yes --update ppa:terraform/terraform
    ${SUDO} apt install --quiet --yes terraform
    ;;

  ubuntu-2*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes terraform
    ;;

  *)
    echo "Unsupported operating system: ${ID}-${VERSION_ID}"
    exit 1
    ;;
  esac
fi

# Install AWS CLI in not present
if is_not_installed aws; then
echo "Installing AWS CLI..."
mkdir -p /tmp/install-aws
# cd /tmp/install-aws
curl -o /tmp/install-aws/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -d /tmp/install-aws/ /tmp/install-aws/awscliv2.zip
sudo bash /tmp/install-aws/aws/install
# sudo ./aws/install
# Configure for AWS CLI, need input from user end
aws configure
fi


# Download git repo
mkdir -p /tmp/node.branch.aws
cd /tmp/node.branch.aws
git clone -b aws.deployment https://github.com/atf828/node.git
cd /tmp/node.branch.aws/node
# Deal with config files for terraform
echo "Deal with config files for terraform..."
if [ -d "/tmp/aws-test" ]; then
  rm -rf /tmp/aws-test
fi
mkdir /tmp/aws-test
cp tests/aws.cluster/terraform/* /tmp/aws-test/

# Set configure of aws instances to be created
# If config file is supplied by user, use it
if [ "${AWS_VM_CONFIG}" != "/tmp/aws-test/dev.tfvars" ]; then
  rm -rf /tmp/aws-test/dev.tfvars
  cp ${AWS_VM_CONFIG} /tmp/aws-test/dev.tfvars
else
  # If no config file supplied by user, use the default one, and set the parameters defined by user
  # Set number of instances for cluster
  read -p "Input the number of master instances for k8s cluster (1 for default):" nb_master
  nb_master=${nb_master:-1}
  read -p "Input the number of worker instances for k8s cluster (2 for default):" nb_worker
  nb_worker=${nb_worker:-2}
  # Set instance_type for instances of cluster
  read -p "Input the instance_type for master instances (t2.micro for default):" itype_master
  itype_master=${itype_master:-t2.micro}
  read -p "Input the instance_type for worker instances (t2.micro for default):" itype_worker
  itype_worker=${itype_worker:-t2.micro}
  # For the default config file, do following:
  # Set number of instances and instance_type defined by user
  old_nb_master="\"no_of_instances\" : \"1\""
  new_nb_master="\"no_of_instances\" : \"${nb_master}\""
  # sed -zi "s/${old_nb_master}/${new_nb_master}/1" dev.tfvars
  old_nb_worker="\"no_of_instances\" : \"2\""
  new_nb_worker="\"no_of_instances\" : \"${nb_worker}\""
  # sed -zi "s/${old_nb_worker}/${new_nb_worker}/1" dev.tfvars
  old_itype_master="\"instance_type\" : \"t2.micro\","
  new_itype_master="\"instance_type\" : \"${itype_master}\","
  # sed -zi "s/${old_itype_master}/${new_itype_master}/1" dev.tfvars
  old_itype_worker="\"instance_type\" : \"t2.micro\","
  new_itype_worker="\"instance_type\" : \"${itype_worker}\","
  # sed -zi "s/${old_itype_worker}/${new_itype_worker}/1" dev.tfvars

  sed -i "8s/.*/${new_nb_master}/" /tmp/aws-test/dev.tfvars
  sed -i "14s/.*/${new_nb_worker}/" /tmp/aws-test/dev.tfvars
  sed -i "7s/.*/${new_itype_master}/" /tmp/aws-test/dev.tfvars
  sed -i "13s/.*/${new_itype_worker}/" /tmp/aws-test/dev.tfvars
fi

# Generate ssh key pair to configure aws cluster
echo "Generate an ssh key pair..."
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/aws-edgenet-test
# Set public key in dev.tfvars
pubkey=$(awk NF $HOME/.ssh/aws-edgenet-test.pub)
# Write into the file supplied by user, or the default one
echo -e "\n public_key = \"${pubkey}\"" >> /tmp/aws-test/dev.tfvars
# echo -e "\n public_key = \"${pubkey}\"" >> "${AWS_VM_CONFIG}"

echo "Create AWS clusters with terraform..."
# Terraform need to run in folder where locates the tf file
cd /tmp/aws-test
terraform fmt
terraform init
terraform plan -var-file=/tmp/aws-test/dev.tfvars -out /tmp/aws-test/edgenet.tfplan
# Terraform plan -var-file="${AWS_VM_CONFIG}" -out /tmp/aws-test/edgenet.tfplan
terraform apply /tmp/aws-test/edgenet.tfplan
terraform output instances >> instances.ret

# Create hosts file for ansible
echo "Set up hosts file for ansible..."
declare -a svr=($(cat /tmp/aws-test/instances.ret | grep "\"kube-" | cut -d'"' -f 2 | grep "kube-"))
declare -a ips=($(cat /tmp/aws-test/instances.ret | grep "\"public_ip\"" | cut -d'"' -f 4))

if ! [ -f /tmp/aws-test/hosts ]; then
  touch /tmp/aws-test/hosts
fi

echo "[masters]" > /tmp/aws-test/hosts
flag=1
for i in "${!ips[@]}"; do
  if [[ "${svr[$i]}" = *"kube-master-"* ]]; then
    echo "${svr[$i]} ansible_host=${ips[$i]} ansible_connection=ssh ansible_user=ubuntu" >> /tmp/aws-test/hosts
  fi
  if [[ "${svr[$i]}" = *"kube-worker-"* ]]; then
    if [[ $flag == 1 ]]; then
    echo -e "\n[workers]" >> /tmp/aws-test/hosts
    flag=0
    fi
    echo "${svr[$i]} ansible_host=${ips[$i]} ansible_connection=ssh ansible_user=ubuntu" >> /tmp/aws-test/hosts
  fi
done

# Ansible needs to run in the repo root location to locate playbook
cd -

echo "Sleep dozen senconds to wait aws launch ready"
sleep 12s
# Run ansible playbook to deploy docker and K8S
echo "Run ansible to deploy k8s and EdgeNet..."
ansible-pull --accept-host-key --extra-vars "ansible_python_interpreter=${PYTHON}" --inventory localhost, \
  --checkout "${EDGENET_REF}" --url "${EDGENET_REPOSITORY}" "${EDGENET_PLAYBOOK}"