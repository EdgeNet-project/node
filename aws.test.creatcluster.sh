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

# Before run the terrafor script, your laptop need to configured as below:
# - AWS.CLI and authetication for IAM user
# - Install terraform
# - To create a key used for login aws cluster, such as by: ssh-keygen -b 2048 -t rsa 
# - Retrieve public_key string from ~/.ssh of your laptop and paste into tests/aws.cluster/terraform/dev.tfvars

# Run terraform to create aws cluster
cd "$(dirname "$0")"
cd tests/aws.cluster/terraform
terraform init
terraform plan -var-file=dev.tfvars -out /tmp/edgenet.tfplan
terraform apply /tmp/edgenet.tfplan