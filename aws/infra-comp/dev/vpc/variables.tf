# Custom (not default) VPC

# #####################################
# AWS
# #####################################
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

# #####################################
# Network
# #####################################
variable "cidr-vpc" {
  description = "Network IP Address Space"
}

variable "cidr-client" {
  description = "Range of client IP addresses"
}

variable "cidr-all" {
  description = "Inbound/Outbound traffic from all IPs"
}

variable "public-subnets" {
  type        = list(string)
  description = "A list of PUBLIC subnets inside the VPC"
}

variable "public-subnet-prefix" {
  description = "Prefix to append to PUBLIC subnets name"
}

variable "create-private-subnets" {
  description = "Create private subnets configuration parameter"
}

variable "private-subnets" {
  type        = list(string)
  description = "A list of PRIVATE subnets inside the VPC"
}

variable "private-subnet-prefix" {
  description = "Prefix to append to PRIVATE subnet name"
}

# #####################################
# Tags
# #####################################
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
