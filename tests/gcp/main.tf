terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
  }
  required_version = ">= 0.14.9"
}

variable "public_key" {
  type = string
}

provider "google" {
  project = "cs-research-25506-10012078-101"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

resource "google_compute_network" "edgenet-test" {
  name = "edgenet-test"
}

resource "google_compute_firewall" "edgenet-test" {
  name    = "edgenet-test"
  network = google_compute_network.edgenet-test.name
  allow {
    protocol = "all"
  }
  source_tags = ["edgenet-test"]
}

resource "google_compute_instance" "debian-9-amd64" {
  name         = "edgenet-test-debian-9-amd64"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-9"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  // TODO: SSH key in metadata
  tags = ["edgenet-test"]
}


resource "google_compute_instance" "centos-7-amd64" {
  name         = "edgenet-test-centos-7-amd64"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "centos-7"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_instance" "fedora-coreos-stable" {
  name         = "edgenet-test-fedora-coreos-stable"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "fedora-coreos-stable"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_instance" "ubuntu-2004-amd64" {
  name         = "edgenet-test-ubuntu-2004-amd64"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-lts"
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
}
