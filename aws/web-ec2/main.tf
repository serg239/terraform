# Create ssh access enabled EC2 instance using Terraform from scratch
#
# Prerequisites:
#   1. Have AWS CLI installed and AWS account configured with secret keys
#   2. A key pair for EC2 instances

terraform {
  required_version = ">= 0.12, < 0.13"
}

# #####################################
#               AWS
# #####################################
# Set up AWS provider - service to set up resources
provider "aws" {
  region = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

# #####################################
# AZs
# Declare the Availability Zones data source
# Accessed by an AWS account within the region configured in the provider.
data "aws_availability_zones" "available" {
  state = "available"
}

# #####################################
#             IAM
# #####################################
# IAM user policy
resource "aws_iam_policy" "web-ec2-user-policy" {
   policy = file("iam_user_policy.json")
}

# #####################################
# Key pair
resource "aws_key_pair" "web-ec2-key" {
      public_key = file(var.pub-keypath)
      key_name   = var.key-name
}

# #####################################
#            AMI
# #####################################
# Image for EC2 instances
data "aws_ami" "ubuntu-16-amd64-hvm" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

# #####################################
#         VPC (Custom Cloud)
# #####################################
# 1. VPC (not default!) for Virtual Private Network
#    to launch AWS resources in a virtual network
# Create:
#   IGW  - Internet Gateway
#   RT   - Route table with a route to the Internet Gateway
#   SUBN - Default subnet in each Availability Zone
# #####################################
resource "aws_vpc" "web-ec2" {
  cidr_block = var.cidr-vpc
  # to use EC2 DNS name in AWS CLI
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = var.cluster-name
  }
}

# #####################################
#        IGW (Internet Gateway)
# #####################################
resource "aws_internet_gateway" "web-ec2-igw" {
  vpc_id = aws_vpc.web-ec2.id

  tags = {
      Name = "${var.cluster-name}-igw"
    }
}

# #####################################
#      Create PUBLIC Route Table
# #####################################
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.web-ec2.id
  route {
    cidr_block = var.cidr-all
    gateway_id = aws_internet_gateway.web-ec2-igw.id
  }

  tags = {
    Name = "${var.cluster-name}-public-rtb"
  }
}

# #####################################
# Create PUBLIC subnets in 2 Availability Zones
# and associate with a PUBLIC Route Table
# #####################################
# Primary Public subnet
resource "aws_subnet" "public-subnet1" {
  vpc_id = aws_vpc.web-ec2.id
  cidr_block = cidrsubnet(var.cidr-vpc, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster-name}-public-subnet1"
  }
}

resource "aws_route_table_association" "public-subnet1" {
  subnet_id = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rtb.id
}

# #####################################
# Secondary Public subnet
resource "aws_subnet" "public-subnet2" {
  vpc_id = aws_vpc.web-ec2.id
  cidr_block = cidrsubnet(var.cidr-vpc, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster-name}-public-subnet2"
  }
}

resource "aws_route_table_association" "public-subnet2" {
  subnet_id = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rtb.id
}

# #####################################
#              EIP
# #####################################
# Attach Elastic IP
resource "aws_eip" "nat-eip" {
# instance = aws_instance.web-ec2.id
 vpc = true
}

# resource "aws_eip_association" "eip-assoc" {
#   instance_id = aws_instance.web-ec2.id
#   allocation_id = aws_eip.nat-eip.id
# }

# #####################################
#             NAT GW
# #####################################
# Create NAT gateway (elastic) on first PUBLIC subnet
resource "aws_nat_gateway" "web-ec2-nat-gw" {
 allocation_id = aws_eip.nat-eip.id
 subnet_id = aws_subnet.public-subnet1.id
 depends_on = [aws_internet_gateway.web-ec2-igw]
}

# #####################################
# Create PRIVATE Route Table with elastic IPs
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.web-ec2.id
  route {
    cidr_block = var.cidr-all
    nat_gateway_id = aws_nat_gateway.web-ec2-nat-gw.id
  }

  tags = {
    Name = "${var.cluster-name}-private-rtb"
  }
}

# #####################################
# Create PRIVATE subnets in 2 Availability Zones
# and associate with a PRIVATE Route Table
# #####################################
# Primary Private subnet
resource "aws_subnet" "private-subnet1" {
  vpc_id = aws_vpc.web-ec2.id
  cidr_block = cidrsubnet(var.cidr-vpc, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster-name}-private-subnet1"
  }
}

resource "aws_route_table_association" "private-subnet1" {
  subnet_id = aws_subnet.private-subnet1.id
  route_table_id = aws_route_table.private-rtb.id
}

# #####################################
# Secondary Private subnet
resource "aws_subnet" "private-subnet2" {
  vpc_id = aws_vpc.web-ec2.id
  cidr_block = cidrsubnet(var.cidr-vpc, 8, 4)
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster-name}-private-subnet2"
  }
}

resource "aws_route_table_association" "private-subnet2" {
  subnet_id = aws_subnet.private-subnet2.id
  route_table_id = aws_route_table.private-rtb.id
}

# #####################################
#               SGs
# #####################################
# Security Group
# * to receive incoming TCP requests on HTTP port
#   from the IP address range 0.0.0.0/0 i.e. from any IP;
# * open SSH port
# #####################################
resource "aws_security_group" "web-ec2-sg" {
  name = "${var.cluster-name}-sg"
  description = "EC2 security group"
  vpc_id = aws_vpc.web-ec2.id

  ingress {
    from_port = var.server-port
    to_port = var.server-port
    protocol = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  // # Allow outgoing traffic to anywhere
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.cidr-all]
   }
}

# #####################################
# Data source for user_data
data "template_file" "web-ec2-user-data" {
  template = file("web-ec2.sh")
  vars = {
    server-port = var.server-port
  }
}

# #####################################
# Launch EC2 Instance in public subnet
resource "aws_instance" "web-ec2" {
  ami           = data.aws_ami.ubuntu-16-amd64-hvm.id
  instance_type = var.ec2-instance-type
  security_groups = [aws_security_group.web-ec2-sg.id]
  subnet_id = aws_subnet.public-subnet1.id
  key_name = var.key-name

  user_data = data.template_file.web-ec2-user-data.rendered

  # user_data = <<-EOF
  #     #!/bin/bash
  #     echo "Hello, World!" > index.html
  #     nohup busybox httpd -f -p var.server-port &
  #     EOF

  tags = {
    Name = var.cluster-name
  }
}
