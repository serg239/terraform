### AWS ###
variable "aws-region" {
  type = string
  description = "AWS region"
}
variable "pub-keypath" {
  type = string
  description = "Path to the Public Key (.pub) file"
}
variable "key-name" {
  type = string
  description = "Key name"
}

### VPC ###
variable "cluster-name" {
  type = string
  description = "Cluster (VPC) name"
}
variable "cidr-vpc" {
  type = string
  description = "VPC CIDR"
}
variable "cidr-all" {
  type = string
  description = "CIDR for ALL Traffic"
}

### EC2 ###
variable "ec2-instance-type" {
  type = string
  description = "EC2 instance type"
}
variable "server-port" {
  type = number
  description = "EC2 HTTP port number"
}
