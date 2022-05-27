terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_vpc" "edgenet-test" {
  cidr_block                       = "10.142.0.0/16"
  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "edgenet-test-subnet" {
  vpc_id                          = aws_vpc.edgenet-test.id
  cidr_block                      = cidrsubnet(aws_vpc.edgenet-test.cidr_block, 8, 0)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.edgenet-test.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
}

resource "aws_internet_gateway" "edgenet-test-ingw" {
  vpc_id = aws_vpc.edgenet-test.id
}

resource "aws_route_table" "edgenet-test-rt" {
  vpc_id = aws_vpc.edgenet-test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edgenet-test-ingw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.edgenet-test-ingw.id
  }
}

resource "aws_route_table_association" "edgenet-test-rta" {
  subnet_id      = aws_subnet.edgenet-test-subnet.id
  route_table_id = aws_route_table.edgenet-test-rt.id
}

resource "aws_security_group" "edgenet-test-sg" {
  name   = "edgenet-test-sg"
  vpc_id = aws_vpc.edgenet-test.id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "edgenet-test-key" {
  key_name   = "aws-edgenet-test"
  public_key = var.public_key
}

# resource "aws_key_pair" "edgenet-test-key" {
#   key_name   = "edgenet-test-key"
#   public_key = var.public_key
# }


locals {
  serverconfig = [
    for srv in var.configuration : [
      for i in range(1, srv.no_of_instances + 1) : {
        instance_name          = "${srv.application_name}-${i}"
        ami                    = srv.ami
        instance_type          = srv.instance_type
        subnet_id              = aws_subnet.edgenet-test-subnet.id
        vpc_id                 = aws_vpc.edgenet-test.id
        vpc_security_group_ids = [aws_security_group.edgenet-test-sg.id]
        key_name               = aws_key_pair.edgenet-test-key.id
      }
    ]
  ]
}

// To Flatten it before using it
locals {
  instances = flatten(local.serverconfig)
}

resource "aws_instance" "k8s" {

  for_each               = { for server in local.instances : server.instance_name => server }
  ami                    = each.value.ami
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.vpc_security_group_ids
  user_data              = <<EOF
#!/bin/bash
echo "Changing the hostname to ${each.value.instance_name}"
hostname ${each.value.instance_name}
echo "${each.value.instance_name}" > /etc/hostname
EOF

  subnet_id = each.value.subnet_id
  key_name  = each.value.key_name
  tags = {
    Name = "${each.value.instance_name}"
  }
}

output "instances" {
  value       = aws_instance.k8s
  description = "All Machine details"
}

output "aws_vpc" {
  value       = aws_vpc.edgenet-test
  description = "Vpc details"
}

output "aws_subnet" {
  value       = aws_subnet.edgenet-test-subnet
  description = "Subnet details"
}
output "aws_route_table" {
  value       = aws_route_table.edgenet-test-rt
  description = "Route table details"
}

output "aws_route_table_association" {
  value       = aws_route_table_association.edgenet-test-rta
  description = "Route table association details"
}

output "aws_security_group" {
  value       = aws_security_group.edgenet-test-sg
  description = "Security group details"
}

output "aws_key_pair" {
  value       = aws_key_pair.edgenet-test-key
  description = "Key pair  details"
}