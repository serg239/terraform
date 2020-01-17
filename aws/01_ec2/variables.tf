### AWS ###
variable "aws-region" {
  type = string
  description = "AWS region"
}
variable "aws-availability-zones" {
  type = string
  description = "AWS zones"
}

### VPC ###
variable "vpc-name" {
  type = string
  description = "VPC name"
}
variable "vpc-cidr" {
  type = string
  description = "VPC CIDR"
}

### EC2 ###
variable "ec2-image-id" {
  type = string
  description = "EC2 AMI identifier"
}
variable "ec2-instance-type" {
  type = string
  description = "EC2 instance type"
}
variable "ec2-port" {
  type = number
  description = "EC2 port number"
}
