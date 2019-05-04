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
private_ip = "172.31.16.107"
key_name = "room-test-key"
ami = "ami-0889b8a448de4fc44"

