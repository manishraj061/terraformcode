terragrunt = {
  terraform {
     source = "/home/ec2-user/work/terraform-ec2-import/modules//ebs"
  }
  include {
     path = "${find_in_parent_folders()}"
  }
}

region = "ap-south-1"
availability_zone = "ap-south-1a"
type = "gp2"
size = 1
size-of-second-ebs = 2
