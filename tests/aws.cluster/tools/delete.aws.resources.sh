#!/bin/bash
# shellcheck disable=SC2086
# vim: et sw=2 ts=2

DIR_BASE="/var/tmp/edgenet.aws.test"
DIR_TERRAFORM="${DIR_BASE}/terraform.config"

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
echo "sleep 1mins waiting for instances to be terminated"
sleep 60s
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
echo "delete AWS resources operation finish..."