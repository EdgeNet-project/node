variable "google_project" {
    type    = string
}

source "amazon-ebs" "edgenet-node" {
    ami_name      = "edgenet-node"
    ami_groups    = "all"
    instance_type = "t3.micro"
    region        = "eu-west-1"
    ssh_username  = "ubuntu"

    source_ami_filter {
        owners  = ["099720109477"]
        filters = {
            name = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20201026"
        }
    }

    force_deregister      = true
    force_delete_snapshot = true
}

source "googlecompute" "edgenet-node" {
    image_name   = "edgenet-node"
    machine_type = "n1-standard-1"
    zone         = "europe-west1-b"
    ssh_username = "root"
    project_id   = "${var.google_project}"
    source_image_family = "ubuntu-minimal-2004-lts"
}

build {
    sources = [
        "source.amazon-ebs.edgenet-node",
        "source.googlecompute.edgenet-node"
    ]

    provisioner "file" {
        source = "bootstrap.sh"
        destination = "/tmp/bootstrap.sh"
    }

    provisioner "shell" {
        inline = [
            "export EDGENET_ASK_CONFIRMATION=0",
            "/tmp/bootstrap.sh"
        ]
    }
}
