provider "aws" {
  region     = "${var.region}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

resource "aws_ebs_volume" "prod-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.size}"
  type              = "${var.type}"
}
resource "aws_ebs_volume" "prod-ebs-2" {
  availability_zone = "${var.availability_zone}"
  size              = "${var.size-of-second-ebs}"
  type              = "${var.type}"
}

resource "aws_ebs_snapshot" "prod-ebs-snapshot" {
  volume_id = "${aws_ebs_volume.prod-ebs.id}"

  tags = {
    Name = "prod-ebs-snap"
  }
}
resource "aws_ebs_snapshot" "prod-ebs-2-snapshot" {
  volume_id = "${aws_ebs_volume.prod-ebs-2.id}"
  tags = {
    Name = "prod-ebs-2-snap"
  }
}

