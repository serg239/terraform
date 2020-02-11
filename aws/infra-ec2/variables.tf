# #####################################
# Notes:
#   Terraform performs automatic conversion from string values
#   to numeric and boolean values based on context.
# #####################################
# AWS
variable "aws-region" {
  description = "AWS region for hosting"
}

variable "pub-key-path" {
  description = "Path to the Public Key (.pub) file"
}

variable "key-name" {
  description = "Key name"
}

# #####################################
# Environment
# #####################################
variable "cluster-name" {
  description = "Cluster (VPC) name"
}

variable "environment" {
  description = "Current environment"
}

# #####################################
# Networks
# #####################################
variable "cidr-vpc" {
  description = "VPC CIDR"
}

variable "cidr-all" {
  description = "CIDR for ALL Traffic"
}

variable "create-private-subnets" {
  description = "Create private subnets configuration parameter"
}

# #####################################
# EC2 instance
# #####################################
variable "ec2-instance-type" {
  description = "EC2 instance type"
}

variable "server-port" {
  description = "EC2 HTTP port number"
}
