provider "aws" {
  region     = "${var.region}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}


resource "aws_instance" "oat-node" {
    ami                         = "${var.ami}"
    availability_zone           = "${var.availability_zone}"
    ebs_optimized               = true
    instance_type               = "${var.instance_type}"
    monitoring                  = false
    key_name                    = "${var.key_name}"
    subnet_id                   = "subnet-37b6fd5f"
    vpc_security_group_ids      = ["sg-04803b84425a747dc"]
    associate_public_ip_address = true
    private_ip                  = "${var.private_ip}"
    source_dest_check           = true

    root_block_device {
        volume_type           = "standard"
        volume_size           = 8
        delete_on_termination = true
    }
}
