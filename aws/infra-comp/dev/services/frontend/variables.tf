# #####################################
# Web server (Frontend)
# #####################################
variable "aws-region" {
  description = "AWS region for hosting"
}

variable "cluster-name" {
  description = "Cluster (VPC) name"
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

# #####################################
# Web (EC2) Instances
# #####################################
variable "ssh-22-port" {
  description = "Port for SSH connections"
}

variable "http-80-port" {
  description = "ELB port for HTTP traffic"
}

variable "http-8080-port" {
  description = "HTTP port on EC2 web instances"
}

variable "web-instance-type" {
  description = "Instance Type (t2.nano, t2.micro, ...)"
}

variable "web-key-pair-name" {
  description = "Key pair to connect to web instance"
}

variable "private-key-path" {
  description = "Path to private key to connect to web instance"
}

# #####################################
# Tags
# #####################################
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
