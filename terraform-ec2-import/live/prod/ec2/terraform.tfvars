terragrunt = {
  terraform {
     source = "/home/ec2-user/work/terraform-ec2-import/modules//ec2"
  }
  include {
     path = "${find_in_parent_folders()}"
  }
}

region = "ap-south-1"
instance_type = "t2.micro"
availability_zone = "ap-south-1a"
private_ip = "172.31.18.40"
key_name = "newaccount"
ami = "ami-0889b8a448de4fc44"
type = "gp2"
size = 1
size-of-second-ebs = 2
description = "encrypted snapshot of "
prod-kms-id = "arn:aws:kms:ap-south-1:125262143502:key/7ebf7f5b-d577-4a70-9da1-7758eb21b9b1"

