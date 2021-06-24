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
  region  = "eu-west-1"
}

resource "aws_instance" "centos-7-x86" {
  ami                    = "ami-0b850cf02cc00fdc8"
  instance_type          = "t3.small"
  key_name               = "maxime.mouchet@lip6.fr:edgenet"
  vpc_security_group_ids = ["sg-0143626c6cdee2192"]
}

resource "aws_instance" "fedora-34-x86" {
  ami                    = "ami-03a2d2ea7d3d04d8c"
  instance_type          = "t3.small"
  key_name               = "maxime.mouchet@lip6.fr:edgenet"
  vpc_security_group_ids = ["sg-0143626c6cdee2192"]
}

resource "aws_instance" "fedora-34-arm64" {
  ami                    = "ami-027de44c10014e5d3"
  instance_type          = "t4g.small"
  key_name               = "maxime.mouchet@lip6.fr:edgenet"
  vpc_security_group_ids = ["sg-0143626c6cdee2192"]
}

resource "aws_instance" "ubuntu-1804-x86" {
  ami                    = "ami-0c259a97cbf621daf"
  instance_type          = "t3.small"
  key_name               = "maxime.mouchet@lip6.fr:edgenet"
  vpc_security_group_ids = ["sg-0143626c6cdee2192"]
}

resource "aws_instance" "ubuntu-2004-arm64" {
  ami                    = "ami-09e0d6fdf60750e33"
  instance_type          = "t4g.small"
  key_name               = "maxime.mouchet@lip6.fr:edgenet"
  vpc_security_group_ids = ["sg-0143626c6cdee2192"]
}

