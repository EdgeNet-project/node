#!/bin/bash
set -eux

git fetch ansible.posix main
git fetch community.general main
git fetch geerlingguy.docker master
git fetch geerlingguy.kubernetes master
git fetch geerlingguy.swap master

git subtree pull --prefix ansible_collections/ansible/posix/ ansible.posix main --squash
git subtree pull --prefix ansible_collections/community/general/ community.general main --squash
git subtree pull --prefix roles/geerlingguy.docker/ geerlingguy.docker master --squash
git subtree pull --prefix roles/geerlingguy.kubernetes/ geerlingguy.kubernetes master --squash
git subtree pull --prefix roles/geerlingguy.swap/ geerlingguy.swap master --squash
