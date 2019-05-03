terragrunt = {
  terraform {
     source = "/root/modules//ec2"
  }
  include {
     path = "${find_in_parent_folders()}"
  }
}

region = "ap-south-1"
instance_type = "t2.micro"
availability_zone = "ap-south-1a"
private_ip = "172.31.25.132"
key_name = "newaccount"
ami = "ami-0889b8a448de4fc44"

