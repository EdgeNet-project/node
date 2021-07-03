terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

variable "public_key" {
  type = string
}

provider "aws" {
  profile = "edgenet"
  region  = "eu-west-1"
}

resource "aws_key_pair" "edgenet-test" {
  key_name   = "edgenet-test"
  public_key = var.public_key
}

resource "aws_vpc" "edgenet-test" {
  cidr_block                       = "10.142.0.0/16"
  assign_generated_ipv6_cidr_block = true
}

resource "aws_subnet" "edgenet-test" {
  vpc_id                          = aws_vpc.edgenet-test.id
  cidr_block                      = cidrsubnet(aws_vpc.edgenet-test.cidr_block, 8, 0)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.edgenet-test.ipv6_cidr_block, 8, 0)
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch         = true
}

resource "aws_internet_gateway" "edgenet-test" {
  vpc_id = aws_vpc.edgenet-test.id
}

resource "aws_route_table" "edgenet-test" {
  vpc_id = aws_vpc.edgenet-test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.edgenet-test.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.edgenet-test.id
  }
}

resource "aws_route_table_association" "edgenet-test" {
  subnet_id      = aws_subnet.edgenet-test.id
  route_table_id = aws_route_table.edgenet-test.id
}

resource "aws_security_group" "edgenet-test" {
  name   = "edgenet-test"
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

resource "aws_instance" "ubuntu-2004-arm64" {
  ami                    = "ami-09e0d6fdf60750e33"
  instance_type          = "t4g.micro"
  key_name               = aws_key_pair.edgenet-test.id
  subnet_id              = aws_subnet.edgenet-test.id
  vpc_security_group_ids = [aws_security_group.edgenet-test.id]
}
