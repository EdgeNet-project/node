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
EDGENET_PLAYBOOK="${EDGENET_PLAYBOOK:-edgenet-aws.yml}"

# Which branch of the node repository to use.
EDGENET_REF="${EDGENET_REF:-aws.deployment}"

# URL of the Git repository containing the playbook to run.
EDGENET_REPOSITORY="${EDGENET_REPOSITORY:-https://github.com/atf828/node.git}"

DIR_BASE="/var/tmp/edgenet.aws.test"
DIR_TERRAFORM="${DIR_BASE}/terraform.config"
DIR_AWSCLI="${DIR_BASE}/awscli.install"
DIR_REPO="${DIR_BASE}/node.branch.aws"
if [ -d ${DIR_BASE} ]; then
  rm -rf ${DIR_BASE}
fi
mkdir ${DIR_BASE}
mkdir ${DIR_TERRAFORM}
mkdir ${DIR_AWSCLI}
mkdir ${DIR_REPO}

# Configure of aws instances to be used by Terraform, the default value will be created by later process
AWS_VM_CONFIG="${AWS_VM_CONFIG:-${DIR_TERRAFORM}/dev.tfvars}"

# Host of remoote servers to be used by Ansible, the default value will be created by later process
HOST_FILE="${HOST_FILE:-${DIR_BASE}/hosts}"


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
    ${SUDO} yum install -y yum-utils
    ${SUDO} yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    ${SUDO} yum install --assumeyes --quiet terraform
    ;;

  fedora-*)
    ${SUDO} dnf install -y dnf-plugins-core
    ${SUDO} dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
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

# Install unzip if not present
if is_not_installed unzip; then
echo "Installing unzip..."
  case "${ID}-${VERSION_ID}" in
  centos-*)
    ${SUDO} yum install --assumeyes --quiet epel-release
    ${SUDO} yum install --assumeyes --quiet unzip
    ;;

  fedora-*)
    ${SUDO} dnf install --assumeyes --quiet unzip
    ;;

  ubuntu-1*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes dirmngr software-properties-common
    ${SUDO} apt install --quiet --yes unzip
    ;;

  ubuntu-2*)
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt update --quiet
    ${SUDO} apt install --quiet --yes unzip
    ;;

  *)
    echo "Unsupported operating system: ${ID}-${VERSION_ID}"
    exit 1
    ;;
  esac
fi

# Install AWS CLI if not present
if is_not_installed aws; then
echo "Installing AWS CLI..."
curl -o ${DIR_AWSCLI}/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip -d ${DIR_AWSCLI} ${DIR_AWSCLI}/awscliv2.zip
sudo bash ${DIR_AWSCLI}/aws/install
# Configure for AWS CLI, need input from user end
aws configure
fi


# Download git repo
cd DIR_REPO
git clone -b aws.deployment https://github.com/atf828/node.git
DIR_NODE="${DIR_REPO}/node"
cd ${DIR_NODE}

# Deal with config files for terraform
echo "Deal with config files for terraform..."
cp tests/aws.cluster/terraform/* ${DIR_TERRAFORM}

# Set configure of aws instances to be created
# If config file is supplied by user, use it
if [ "${AWS_VM_CONFIG}" != "${DIR_TERRAFORM}/dev.tfvars" ]; then
  rm -rf ${DIR_TERRAFORM}/dev.tfvars
  cp ${AWS_VM_CONFIG} ${DIR_TERRAFORM}/dev.tfvars
else
  # If no config file supplied by user, use the default one, and set the parameters defined by user
  # Set number of instances for cluster
  read -p "Input the number of master instances for k8s cluster (1 for default, press <Enter> for default):" nb_master
  nb_master=${nb_master:-1}
  read -p "Input the number of worker instances for k8s cluster (1 for default, press <Enter> for default):" nb_worker
  nb_worker=${nb_worker:-1}
  # Set instance_type for instances of cluster
  itype_default="t2.micro"
  read -p "Input the instance_type for master instances (${itype_default} for default, press <Enter> for default):" itype_master
  itype_master=${itype_master:-${itype_default}}
  read -p "Input the instance_type for worker instances (${itype_default} for default, press <Enter> for default):" itype_worker
  itype_worker=${itype_worker:-${itype_default}}

  new_nb_master="\"no_of_instances\" : \"${nb_master}\""
  new_nb_worker="\"no_of_instances\" : \"${nb_worker}\""
  new_itype_master="\"instance_type\" : \"${itype_master}\","
  new_itype_worker="\"instance_type\" : \"${itype_worker}\","

  sed -i "8s/.*/${new_nb_master}/" ${DIR_TERRAFORM}/dev.tfvars
  sed -i "14s/.*/${new_nb_worker}/" ${DIR_TERRAFORM}/dev.tfvars
  sed -i "7s/.*/${new_itype_master}/" ${DIR_TERRAFORM}/dev.tfvars
  sed -i "13s/.*/${new_itype_worker}/" ${DIR_TERRAFORM}/dev.tfvars
fi

# Generate ssh key pair to configure aws cluster
echo "Generate an ssh key pair..."
ssh-keygen -q -t rsa -N '' -f $HOME/.ssh/aws-edgenet-test <<<y >/dev/null 2>&1
# Set public key in dev.tfvars
pubkey=$(awk NF $HOME/.ssh/aws-edgenet-test.pub)
# Write into the file supplied by user, or the default one
echo -e "\n public_key = \"${pubkey}\"" >> ${DIR_TERRAFORM}/dev.tfvars

# Delete AWS key-pair if have been created before 
aws ec2 delete-key-pair --key-name aws-edgenet-test

echo "Create AWS clusters with terraform..."
# Terraform need to run in folder where locates the tf file
cd ${DIR_TERRAFORM}
terraform fmt
terraform init
terraform plan -var-file=${DIR_TERRAFORM}/dev.tfvars -out ${DIR_TERRAFORM}/edgenet.tfplan
terraform apply ${DIR_TERRAFORM}/edgenet.tfplan

terraform output instances >> ${DIR_TERRAFORM}/aws_instances.ret
terraform output aws_vpc >> ${DIR_TERRAFORM}/aws_vpc.ret
terraform output aws_route_table >> ${DIR_TERRAFORM}/aws_route_table.ret
terraform output aws_route_table_association >> ${DIR_TERRAFORM}/aws_route_table_association.ret
terraform output aws_security_group >> ${DIR_TERRAFORM}/aws_security_group.ret
terraform output aws_subnet >> ${DIR_TERRAFORM}/aws_subnet.ret
terraform output aws_key_pair >> ${DIR_TERRAFORM}/aws_key_pair.ret

# Create hosts file for ansible
echo "Set up hosts file for ansible..."
declare -a svr=($(cat ${DIR_TERRAFORM}/aws_instances.ret | grep "\"kube-" | cut -d'"' -f 2 | grep "kube-"))
declare -a ips=($(cat ${DIR_TERRAFORM}/aws_instances.ret | grep "\"public_ip\"" | cut -d'"' -f 4))

if ! [ -f ${DIR_BASE}/hosts ]; then
  touch ${DIR_BASE}/hosts
fi

echo "[masters]" > ${DIR_BASE}/hosts
flag=1
for i in "${!ips[@]}"; do
  if [[ "${svr[$i]}" = *"kube-master-"* ]]; then
    echo "${svr[$i]} ansible_host=${ips[$i]} ansible_connection=ssh ansible_user=ubuntu" >> ${DIR_BASE}/hosts
  fi
  if [[ "${svr[$i]}" = *"kube-worker-"* ]]; then
    if [[ $flag == 1 ]]; then
    echo -e "\n[workers]" >> ${DIR_BASE}/hosts
    flag=0
    fi
    echo "${svr[$i]} ansible_host=${ips[$i]} ansible_connection=ssh ansible_user=ubuntu" >> ${DIR_BASE}/hosts
  fi
done

# Ansible needs to run in the repo root location to locate playbook
cd ${DIR_NODE}

# Run ansible playbook to deploy docker and K8S
echo "Run ansible to deploy k8s and EdgeNet..."

ansible-playbook -i "${HOST_FILE}" "${EDGENET_PLAYBOOK}"

# # Update vars/kubenetes.aws.yml with info from master nodes
echo "Update kubenetes.aws.yml file..."
if ! [ -f ${DIR_BASE}/config ]; then
  echo "Error: do not find ${DIR_BASE}/config file."
  exit 1
fi

if ! [ -f ${DIR_BASE}/id_rsa.pub ]; then
  echo "Error: do not find ${DIR_BASE}/id_rsa.pub file."
  exit 1
fi

master_ip=$(grep "server: " ${DIR_BASE}/config | awk -F ':|//' '{print $4}')
server_addr=$(echo "kubeconfig_url: http://${master_ip}:8082/config" | sed 's/\//\\\//g')
edgenet_public_key=$(cat ${DIR_BASE}/id_rsa.pub | sed 's/\//\\\//g')

sed -i "s/kubeconfig_url.*/${server_addr}/1" vars/edgenet-aws.yml
sed -i "s/edgenet_ssh_public_key.*/edgenet_ssh_public_key: ${edgenet_public_key}/1" vars/edgenet-aws.yml

# Deploy worker node
echo "Run ansible to deploy EdgeNet on worker nodes..."
ansible-playbook -i "${HOST_FILE}" edgenet-aws-node.yml

# TODO: Insert EdgeNet testing scripts here


# Delete instances after testing

cd ${DIR_TERRAFORM}
declare -a instance_ids=($(cat ${DIR_TERRAFORM}/aws_instances.ret | grep "\"id\"" | cut -d'"' -f 4))
for i in "${!instance_ids[@]}"; do
  if [[ "${instance_ids[$i]}" = "i-"* ]]; then
    aws ec2 terminate-instances --instance-ids ${instance_ids[$i]}
  fi
done

key_id=$(cat ${DIR_TERRAFORM}/aws_key_pair.ret | grep "\"id\"" | cut -d'"' -f 4)
aws_security_group_id=$(cat ${DIR_TERRAFORM}/aws_security_group.ret | grep "\"id\"" | cut -d'"' -f 4)
subnet_id=$(cat ${DIR_TERRAFORM}/aws_subnet.ret | grep "\"id\"" | cut -d'"' -f 4)
aws_route_table_id=$(cat ${DIR_TERRAFORM}/aws_route_table.ret | grep "\"id\"" | cut -d'"' -f 4)
vpc_id=$(cat ${DIR_TERRAFORM}/aws_vpc.ret | grep "\"id\"" | cut -d'"' -f 4)
association_id=$(cat ${DIR_TERRAFORM}/aws_route_table_association.ret | grep "\"id\"" | cut -d'"' -f 4)

# Sleep for waiting instances to be terminated, or else delete subnet will be failed due to dependency problems
echo "sleep 2mins waiting for instances to be terminated"
sleep 120s
aws ec2 disassociate-route-table --association-id ${association_id}
aws ec2 delete-key-pair --key-name ${key_id}
aws ec2 delete-subnet --subnet-id ${subnet_id}
aws ec2 delete-security-group --group-id ${aws_security_group_id}
aws ec2 delete-route-table --route-table-id ${aws_route_table_id}

# To prevent dependency problem at deleting vpc, must detach and delete internet gateway
InternetGatewayId=$(aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc_id | grep InternetGatewayId | head -1 | cut -d'"' -f 4)
aws ec2 detach-internet-gateway --internet-gateway-id  ${InternetGatewayId} --vpc-id ${vpc_id}
aws ec2 delete-internet-gateway --internet-gateway-id ${InternetGatewayId}

aws ec2 delete-vpc --vpc-id ${vpc_id}