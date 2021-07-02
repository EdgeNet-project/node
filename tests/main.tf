terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.1.0"
    }
  }
  required_version = ">= 0.14.9"
}

// TODO: Azure

variable "public_key" {
  type = string
}

provider "aws" {
  profile = "edgenet"
  region  = "eu-west-1"
}

provider "google" {
  project = "cs-research-25506-10012078-101"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
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

//resource "google_compute_network" "edgenet-test" {
//  name = "edgenet-test"
//}
//
//resource "google_compute_firewall" "edgenet-test" {
//  name    = "edgenet-test"
//  network = google_compute_network.edgenet-test.name
//  allow {
//    protocol = "all"
//  }
//  source_tags = ["edgenet-test"]
//}
//
//resource "google_compute_instance" "debian-9-amd64" {
//  name         = "edgenet-test-debian-9-amd64"
//  machine_type = "e2-micro"
//  boot_disk {
//    initialize_params {
//      image = "debian-9"
//    }
//  }
//  network_interface {
//    network = "default"
//    access_config {}
//  }
//  // TODO: SSH key in metadata
//  tags = ["edgenet-test"]
//}

//
//resource "google_compute_instance" "centos-7-amd64" {
//  name         = "edgenet-test-centos-7-amd64"
//  machine_type = "e2-micro"
//  boot_disk {
//    initialize_params {
//      image = "centos-7"
//    }
//  }
//  network_interface {
//    network = "default"
//    access_config {}
//  }
//}
//
////resource "google_compute_instance" "fedora-coreos-stable" {
////  name         = "edgenet-test-fedora-coreos-stable"
////  machine_type = "e2-micro"
////  boot_disk {
////    initialize_params {
////      image = "fedora-coreos-stable"
////    }
////  }
////  network_interface {
////    network = "default"
////    access_config {}
////  }
////}
//
//resource "google_compute_instance" "ubuntu-2004-amd64" {
//  name         = "edgenet-test-ubuntu-2004-amd64"
//  machine_type = "e2-micro"
//  boot_disk {
//    initialize_params {
//      image = "ubuntu-2004-lts"
//    }
//  }
//  network_interface {
//    network = "default"
//    access_config {}
//  }
//}
//
//resource "scaleway_account_ssh_key" "edgenet-test" {
//  name       = "edgenet-test"
//  public_key = var.public_key
//}
//
//resource "scaleway_instance_security_group" "edgenet-test" {
//  name                    = "edgenet-test"
//  inbound_default_policy  = "accept"
//  outbound_default_policy = "accept"
//}
//
//resource "scaleway_instance_ip" "ubuntu-2004-amd64" {}
//resource "scaleway_instance_server" "ubuntu-2004-amd64" {
//  type              = "DEV1-S"
//  image             = "ubuntu_focal"
//  ip_id             = scaleway_instance_ip.ubuntu-2004-amd64.id
//  security_group_id = scaleway_instance_security_group.edgenet-test.id
//}
