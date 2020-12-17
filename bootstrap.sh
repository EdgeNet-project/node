#!/bin/sh

set -eu
export DEBIAN_FRONTEND=noninteractive

# TODO: Detect sudo and don't use it if not present.

ID="unknown"
. /etc/os-release

case ${ID} in
    centos)
        sudo yum install --assumeyes epel-release
        sudo yum install --assumeyes ansible git
        ;;

    fedora)
        sudo dnf install --assumeyes ansible git
        ;;

    debian)
        sudo apt update
        sudo apt install --yes dirmngr software-properties-common
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        sudo apt-add-repository --update --yes \
            "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
        sudo apt install --yes ansible git
        ;;

    ubuntu)
        sudo apt update
        sudo apt install --yes dirmngr software-properties-common
        sudo apt-add-repository --yes --update ppa:ansible/ansible
        sudo apt install --yes ansible git
        ;;

    *)
        echo "Unsupported operating system: ${ID}"
        exit 1
        ;;
esac

ansible-playbook -c local -i localhost, /node/node.yml
