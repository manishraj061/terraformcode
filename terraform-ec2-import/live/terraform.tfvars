terragrunt = {
  remote_state {
    backend = "s3"
    config {
      bucket         = "manish-terraform-state"
      key            = "${path_relative_to_include()}/terraform.tfstate"
      region         = "ap-south-1"
      encrypt        = true
      dynamodb_table = "my-lock-table"
    }
  }
}
