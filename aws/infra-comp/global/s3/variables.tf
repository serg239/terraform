variable "aws-region" {
  type = string
  description = "AWS region for the network hosting"
}

variable "bucket-name" {
  type = string
  description = "GLOBALLY unique Backet name for TF states"
}

variable "ddb-table-name" {
  type        = string
  description = "DynamoDB Table name (unique in the account) to save locks of the TF states"
}
