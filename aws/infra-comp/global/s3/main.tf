# Use Amazon S3 (Simple Storage Service)
# which is Amazon managed file store
# as Remote State Storage.
# S3:
# * supports server-side encryption, AES-256
# * supports versioning (roll back)
# * free tier
# Note:
#   S3 is eventually consistent
terraform {
  required_version = ">= 0.12, < 0.13"
}

# #####################################
# AWS provider
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile = "aws-admin-user"
  region  = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.1"
}

# Enable logging
# resource "aws_s3_bucket" "infra-comp-log-bucket" {
#   bucket = "infra-comp-log-bucket"
#   acl    = "log-delivery-write"
# }

# #####################################
# S3 Bucket to store the state files in
# #####################################
resource "aws_s3_bucket" "this" {
  bucket = var.bucket-name
  # acl = "private"

  # lifecycle {
  #   prevent_destroy = true
  # }

  # This is only here so we can destroy the bucket as part of automated tests.
  # YOU SHOUL NOT COPY THIS FOR PRODUCTION
  force_destroy = true

  # Enable versioning to see a full revision history of state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # logging {
  #     target_bucket = aws_s3_bucket.infra-comp-log-bucket.id
  #     target_prefix = "log/"
  # }

  tags = {
      Name = "S3 Remote Terraform State Storage"
      Environment = "stage"
  }
}

# #####################################
# Backend Resource - Dynamo DB table
# to save Terraform locks for project states
# #####################################
resource "aws_dynamodb_table" "this" {
  name           = var.ddb-table-name
  # billing_mode = "PAY_PER_REQUEST"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5         # required if billing_mode is PROVISIONED
  write_capacity = 5         # required if billing_mode is PROVISIONED
  hash_key       = "LockID"  # partition key, must also be defined as an attribute

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
      Name = "DynamoDB Terraform State Lock Table"
      Environment = "stage"
  }
}
