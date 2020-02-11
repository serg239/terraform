# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  config = {
    bucket  = "infra-comp-bucket-serg239"
    key = "${path_relative_to_include()}/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
    dynamodb_table = "infra-comp"
  }
}

# Configure Terragrunt to use DynamoDB for locking
lock = {
  backend = "dynamodb"
  config = {
    state_file_id = "global/s3"
  }
}
