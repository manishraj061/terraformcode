provider "aws" {
  region     = "${var.region}"
}

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}


resource "aws_instance" "prod-node" {
    ami                         = "${var.ami}"
    availability_zone           = "${var.availability_zone}"
    ebs_optimized               = false
    instance_type               = "${var.instance_type}"
    monitoring                  = false
    key_name                    = "${var.key_name}"
    subnet_id                   = "subnet-37b6fd5f"
    vpc_security_group_ids      = ["sg-04803b84425a747dc"]
    associate_public_ip_address = true
    private_ip                  = "${var.private_ip}"
    source_dest_check           = true

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = false
    }
}
#Import volumes into terraform
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
#Importing data of ec2 instance
data "aws_instance" "prod-node" {
      filter {
            name   = "tag:Name"
            values = ["prod-node"]
  }
}
# Stopping ec2 instance to create snapshot
resource "null_resource" "stop-ec2-instances" {
       provisioner "local-exec" {
              command = "aws ec2 stop-instances --instance-ids ${data.aws_instance.prod-node.id} --profile oat-kms-role"
  }
}

#Taking snapshot of non-root-ebs volumes
resource "aws_ebs_snapshot" "prod-ebs-snapshot" {
  volume_id = "${aws_ebs_volume.prod-ebs.id}"

  tags = {
    Name = "prod-ebs-snap"
  }
  depends_on = ["null_resource.stop-ec2-instances"] 
}
resource "aws_ebs_snapshot" "prod-ebs-2-snapshot" {
  volume_id = "${aws_ebs_volume.prod-ebs-2.id}"
  tags = {
    Name = "prod-ebs-2-snap"
  }
  depends_on = ["null_resource.stop-ec2-instances","aws_ebs_snapshot.prod-ebs-snapshot"]
}

#Taking snapshot of root-ebs volumes
resource "aws_ebs_snapshot" "prod-root-ebs-snapshot" {
  volume_id = "${data.aws_instance.prod-node.root_block_device.0.volume_id}"
   tags = {
      Name = "prod-root-ebs-snap"
   }
   depends_on = ["null_resource.stop-ec2-instances","aws_ebs_snapshot.prod-ebs-2-snapshot"]
}
#Encrypting Non-root snapshot usin CMK's
resource "aws_ebs_snapshot_copy" "prod-ebs-snapshot_copy" {
  source_snapshot_id = "${aws_ebs_snapshot.prod-ebs-snapshot.id}"
  source_region      = "${var.region}"
  encrypted          = true
  kms_key_id         = "${var.prod-kms-id}"
  description        = "${var.description}"
  tags = {
    Name = "prod-ebs-snapshot-copy"
  }
  depends_on = ["aws_ebs_snapshot.prod-ebs-snapshot"]
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
  depends_on = ["aws_ebs_snapshot.prod-ebs-2-snapshot"]
}
#Encrypting root ebs snapshot usin CMK's
resource "aws_ebs_snapshot_copy" "prod-root-ebs_copy" {
     source_snapshot_id = "${aws_ebs_snapshot.prod-root-ebs-snapshot.id}"
     source_region      = "${var.region}"
     encrypted          = true
     kms_key_id         = "${var.prod-kms-id}"
     description        = "${var.description}"
     tags = {
         Name = "prod-root-ebs-snapshot-copy"
      }
     depends_on = ["aws_ebs_snapshot.prod-root-ebs-snapshot"]
}

#Creating encrypting volumes using above encrypted snapshot

resource "aws_ebs_volume" "encrypted-prod-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = 1
  snapshot_id       = "${aws_ebs_snapshot_copy.prod-ebs-snapshot_copy.id}"
  tags = {
    Name = "encrypted-prod-ebs"
  }
  depends_on = ["aws_ebs_snapshot_copy.prod-ebs-snapshot_copy"]
}

resource "aws_ebs_volume" "encrypted-prod-2-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = 2
  snapshot_id       = "${aws_ebs_snapshot_copy.prod-ebs-2-snapshot_copy.id}"
  tags = {
    Name = "encrypted-prod-2-ebs"
  }
  depends_on = ["aws_ebs_snapshot_copy.prod-ebs-2-snapshot_copy"]
}
#Creating encrypted root volumes using above root encrypted snapshot

resource "aws_ebs_volume" "encrypted-prod-root-ebs" {
  availability_zone = "${var.availability_zone}"
  size              = "${data.aws_instance.prod-node.root_block_device.0.volume_size}"
  snapshot_id       = "${aws_ebs_snapshot_copy.prod-root-ebs_copy.id}"
  tags = {
    Name = "encrypted-prod-root-ebs"
  }
  depends_on = ["aws_ebs_snapshot_copy.prod-root-ebs_copy"]
}


#Detaching ebs non-root-ebs volumes

resource "null_resource" "detach-prod-ebs" {
       provisioner "local-exec" {
              command = "aws ec2 detach-volume --volume-id ${aws_ebs_volume.prod-ebs.id} --profile oat-kms-role"
  }
       depends_on = ["aws_ebs_volume.encrypted-prod-ebs"]
}

resource "null_resource" "detach-prod-ebs-2" {
       provisioner "local-exec" {
              command = "aws ec2 detach-volume --volume-id ${aws_ebs_volume.prod-ebs-2.id} --profile oat-kms-role"
  }
       depends_on = ["aws_ebs_volume.encrypted-prod-2-ebs"]
}

resource "null_resource" "detach-root-ebs" {
         provisioner "local-exec" {
               command = "aws ec2 detach-volume --volume-id ${data.aws_instance.prod-node.root_block_device.0.volume_id} --profile oat-kms-role"
         }
         depends_on = ["aws_ebs_volume.encrypted-prod-root-ebs"]
}

#Attaching new encrypted root volume to ec2 instances
resource "aws_volume_attachment" "attach-prod-root-ebs" {
  device_name = "/dev/xvda"
  volume_id   = "${aws_ebs_volume.encrypted-prod-root-ebs.id}"
  instance_id = "${data.aws_instance.prod-node.id}"
  depends_on = ["null_resource.detach-root-ebs"]
}


#Attaching new encrypted volumes to ec2 instance
resource "aws_volume_attachment" "attach-prod-ebs" {
  device_name = "/dev/sdf"
  volume_id   = "${aws_ebs_volume.encrypted-prod-ebs.id}"
  instance_id = "${data.aws_instance.prod-node.id}"
  depends_on = ["null_resource.detach-prod-ebs"]
}

resource "aws_volume_attachment" "attach-prod-ebs-2" {
  device_name = "/dev/sdg"
  volume_id   = "${aws_ebs_volume.encrypted-prod-2-ebs.id}"
  instance_id = "${data.aws_instance.prod-node.id}"
  depends_on = ["null_resource.detach-prod-ebs-2"]
}

#Start ec2 instance after finish activity
resource "null_resource" "start-ec2-instances" {
       provisioner "local-exec" {
              command = "aws ec2 start-instances --instance-ids ${data.aws_instance.prod-node.id} --profile oat-kms-role"
  }
       depends_on = ["aws_volume_attachment.attach-prod-root-ebs","aws_volume_attachment.attach-prod-ebs","aws_volume_attachment.attach-prod-ebs-2"]
}

