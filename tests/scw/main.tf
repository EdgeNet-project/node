terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "2.1.0"
    }
  }
  required_version = ">= 0.14.9"
}

variable "public_key" {
  type = string
}

provider "scaleway" {
  zone   = "fr-par-1"
  region = "fr-par"
}

resource "scaleway_account_ssh_key" "edgenet-test" {
  name       = "edgenet-test"
  public_key = var.public_key
}

resource "scaleway_instance_security_group" "edgenet-test" {
  name                    = "edgenet-test"
  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"
}

resource "scaleway_instance_ip" "ubuntu-2004-amd64" {}
resource "scaleway_instance_server" "ubuntu-2004-amd64" {
  type              = "DEV1-S"
  image             = "ubuntu_focal"
  ip_id             = scaleway_instance_ip.ubuntu-2004-amd64.id
  security_group_id = scaleway_instance_security_group.edgenet-test.id
}
