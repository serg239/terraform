# #####################################
# AWS
# #####################################
variable "aws-region" {
  description = "AWS region for hosting the network"
}

# #####################################
# Environment
# #####################################
variable "cluster-name" {
  description = "Cluster name"
}

# #####################################
# S3 bucket
# #####################################
variable "bucket-name" {
  description = "S3 bucket name (state files)"
}

# #####################################
# Network
# #####################################
variable "cidr-all" {
  description = "Inbound/Outbound traffic from all IPs"
}

variable "cidr-client" {
  description = "Range of client IP addresses"
}

variable "create-db-network" {
  description = "Create database network attribute"
}

variable "database-subnets" {
  type        = list(string)
  description = "A list of database subnets"
  default     = []
}

variable "database-subnet-prefix" {
  description = "Suffix to append to database subnets name"
}

# #####################################
# ELB
# #####################################
variable "ssh-22-port" {
  description = "Port for SSH connections"
}

# #####################################
# DB on RDS
# #####################################
variable "rds-identifier" {
  description = "DB (RDS) instance identifier"
}

variable "rds-storage-size" {
  description = "Storage size in GB"
}

variable "rds-storage-type" {
  description = "Storage type"
}

variable "rds-engine" {
  description = "DB (RDS) type"
}

variable "rds-engine-version" {
  description = "DB (RDS) version"
}

variable "rds-instance-class" {
  description = "RDS instance class"
}

variable "database-5432-port" {
  description = "DB (RDS) port number"
}

variable "database-username" {
  description = "DB (RDS) username"
}

variable "database_password" {
  description = "DB (RDS) user password; env.var. TF_VAR_db_password"
}

variable "timeouts" {
  type        = map(string)
  description = "Updated Terraform resource management timeouts. Applies to 'aws_db_instance' in particular to permit resource management times"
  default = {
    create = "20m"
    update = "40m"
    delete = "20m"
  }
}

# #####################################
# Tags
# #####################################
variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}
