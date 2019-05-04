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
resource "aws_ebs_snapshot_copy" "prod-ebs-snapshot_copy" {
  source_snapshot_id = "${aws_ebs_snapshot.prod-ebs-snapshot.id}"
  source_region      = "${var.region}"
  encrypted          = true
  kms_key_id         = "${var.prod-kms-id}"
  description        = "${var.description}"
  tags = {
    Name = "prod-ebs-snapshot-copy"
  }
}

resource "aws_ebs_snapshot_copy" "prod-ebs-2-snapshot_copy" {
  source_snapshot_id = "${aws_ebs_snapshot.prod-ebs-2-snapshot.id}"
  source_region      = "${var.region}"
  encrypted          = true
  kms_key_id         = "${var.prod-kms-id}"
  description        = "${var.description}"
  tags = {
    Name = "prod-ebs-2-snapshot_copy"
  }
}
resource "aws_ebs_volume" "encrypted-prod-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = 1
  snapshot_id       = "${aws_ebs_snapshot_copy.prod-ebs-snapshot_copy.id}"
  tags = {
    Name = "encrypted-prod-ebs"
  }
}

resource "aws_ebs_volume" "encrypted-prod-2-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = 2
  snapshot_id       = "${aws_ebs_snapshot_copy.prod-ebs-2-snapshot_copy.id}"
  tags = {
    Name = "encrypted-prod-2-ebs"
  }
}

