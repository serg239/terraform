# #####################################
# Create EC2 instance in custom VPC
# #####################################
# Prerequisites:
#   1. Have AWS CLI installed and AWS account configured with secret keys
#   2. A key pair for EC2 instances
# Variables:
#   To create Private network: create-private-subnets = true
# #####################################
# Usage:
#   terragrunt plan -out=2020_02_09.tfplan -input=false -lock=true
#   terragrunt apply 2020_02_09.tfplan
#   terragrant destroy
# #####################################

terraform {
  required_version = ">= 0.12, < 0.13"
}

# #####################################
#               AWS
# #####################################
# Set up AWS provider - service to set up resources
provider "aws" {

  shared_credentials_file = "~/.aws/credentials"
  profile = var.key-name
  region  = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.1"
}

# #####################################
# AZs
# Declare the Availability Zones data source
# Accessed by an AWS account within the region configured in the provider
data "aws_availability_zones" "available" {
  state = "available"
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
# Custom VPC
# #####################################
# 1. VPC (not default!) for Virtual Networks to launch AWS resources in
# Create:
#   IGW    - Internet Gateway
#   RTB    - Route table with a route to the Internet Gateway
#   SUBNET - Public/Private subnets in each Availability Zone
# #####################################
resource "aws_vpc" "this" {
  cidr_block = var.cidr-vpc
  # to use EC2 DNS name in AWS CLI
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.cluster-name}-vpc"
    Environment = var.environment
  }
}

# #####################################
# IGW (Internet Gateway)
# #####################################
resource "aws_internet_gateway" "infra-ec2-igw" {
  vpc_id = aws_vpc.this.id

  tags = {
      Name        = "${var.cluster-name}-igw"
      Environment = var.environment
    }
}

# #####################################
# PUBLIC Route Table
# #####################################
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.cidr-all
    gateway_id = aws_internet_gateway.infra-ec2-igw.id
  }

  tags = {
    Name        = "${var.cluster-name}-public-rtb"
    Environment = var.environment
  }
}

# #####################################
# Primary Public subnet in AZ1
# #####################################
resource "aws_subnet" "public-subnet1" {
  vpc_id            = aws_vpc.this.id
  # plus 8, start from 1
  cidr_block        = cidrsubnet(var.cidr-vpc, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[0]
  # assign public IPs to the instances in subnet
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.cluster-name}-public-subnet1"
    Environment = var.environment
  }
}

# #####################################
# RTA for Public Subnet 1
# #####################################
resource "aws_route_table_association" "public-rta1" {
  subnet_id      = aws_subnet.public-subnet1.id
  route_table_id = aws_route_table.public-rtb.id
}

# #####################################
# Secondary Public subnet in AZ2
# #####################################
resource "aws_subnet" "public-subnet2" {
  vpc_id            = aws_vpc.this.id
  # plus 8, start from 3
  cidr_block        = cidrsubnet(var.cidr-vpc, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[1]
  # assign public IPs to the instances in subnet
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.cluster-name}-public-subnet2"
    Environment = var.environment
  }
}

# #####################################
# RTA for Public Subnet 2
# #####################################
resource "aws_route_table_association" "public-rta2" {
  subnet_id      = aws_subnet.public-subnet2.id
  route_table_id = aws_route_table.public-rtb.id
}

# #####################################
# EIP
# #####################################
# Attach Elastic IP
resource "aws_eip" "this" {
  count = var.create-private-subnets ? 1 : 0
  vpc   = true
  # instance = aws_instance.infra-ec2-instance.id
}

# resource "aws_eip_association" "nat-eip-assoc" {
#   instance_id   = aws_instance.infra-ec2-instance.id
#   allocation_id = aws_eip.this.id
# }

# #####################################
# NAT GW
# #####################################
# Create NAT gateway (elastic) on first PUBLIC subnet
resource "aws_nat_gateway" "infra-ec2-nat-gw" {
  count = var.create-private-subnets ? 1 : 0

  allocation_id = aws_eip.this[count.index].id
  subnet_id     = aws_subnet.public-subnet1.id

  depends_on    = [aws_internet_gateway.infra-ec2-igw]
}

# #####################################
# PRIVATE Route Table with elastic IPs
# #####################################
resource "aws_route_table" "private-rtb" {
  count  = var.create-private-subnets ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = var.cidr-all
    nat_gateway_id = aws_nat_gateway.infra-ec2-nat-gw[count.index].id
  }

  tags = {
    Name        = "${var.cluster-name}-private-rtb"
    Environment = var.environment
  }
}

# #####################################
# Primary Private subnet
# #####################################
resource "aws_subnet" "private-subnet1" {
  count  = var.create-private-subnets ? 1 : 0
  vpc_id = aws_vpc.this.id
  # plus 8, start from 2
  cidr_block        = cidrsubnet(var.cidr-vpc, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[0]
  # don't assign public IPs to the instances in subnet
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.cluster-name}-private-subnet1"
    Environment = var.environment
  }
}

# #####################################
# RTA for Private Subnet 1
# #####################################
resource "aws_route_table_association" "private-rta1" {
  count = var.create-private-subnets ? 1 : 0
  subnet_id      = aws_subnet.private-subnet1[count.index].id
  route_table_id = aws_route_table.private-rtb[count.index].id
}

# #####################################
# Secondary Private subnet
# #####################################
resource "aws_subnet" "private-subnet2" {
  count  = var.create-private-subnets ? 1 : 0
  vpc_id = aws_vpc.this.id
  # plus 8, start from 4
  cidr_block        = cidrsubnet(var.cidr-vpc, 8, 4)
  availability_zone = data.aws_availability_zones.available.names[1]
  # don't assign public IPs to the instances in subnet
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.cluster-name}-private-subnet2"
    Environment = var.environment
  }
}

# #####################################
# RTA for Private Subnet 2
# #####################################
resource "aws_route_table_association" "private-rta2" {
  count          = var.create-private-subnets ? 1 : 0
  subnet_id      = aws_subnet.private-subnet2[count.index].id
  route_table_id = aws_route_table.private-rtb[count.index].id
}

# #####################################
# SG for EC2 instances
# #####################################
# Security Group
# * to receive incoming TCP requests on HTTP port
#   from the IP address range 0.0.0.0/0 i.e. from any IP;
# * open SSH port
# #####################################
resource "aws_security_group" "infra-ec2-sg" {
  name        = "${var.cluster-name}-ec2-sg"
  description = "EC2 security group"

  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = var.server-port
    to_port     = var.server-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  // # Allow outgoing traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-all]
   }
}

# #####################################
# Data source for user_data
# #####################################
data "template_file" "user-data" {
  template = file("infra-ec2.sh")
  vars = {
    server-port = var.server-port
  }
}

# #####################################
# Launch EC2 Instance in public subnet
# #####################################
resource "aws_instance" "ec2-instance" {
  ami             = data.aws_ami.ubuntu-16-amd64-hvm.id
  instance_type   = var.ec2-instance-type
  security_groups = [aws_security_group.infra-ec2-sg.id]
  subnet_id       = aws_subnet.public-subnet1.id
  key_name        = var.key-name

  user_data = data.template_file.user-data.rendered

  # user_data = <<-EOF
  #     #!/bin/bash
  #     echo "Hello, World!" > index.html
  #     nohup busybox httpd -f -p var.server-port &
  #     EOF

  tags = {
    Name        = "${var.cluster-name}-ec2-instance"
    Environment = var.environment
  }
}
