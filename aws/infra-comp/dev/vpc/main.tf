# #####################################
# Custom VPC to launch AWS resources
# #####################################
# Creates:
#   IGW         - Internet Gateway
#   Public RTB  - Public Route table with a route to the IGW
#   Private RTB - Optional Private Route table with a route to NAT IGW
#   SUBN        - Private/Public Subnets in each Availability Zone
# #####################################
# Notes:
#   * To create Private network:
#       create-private-subnets = true
# #####################################
# Usage:
#   terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true
#   terragrunt apply 2020_02_10.tfplan
#   terragrant destroy
# #####################################

terraform {
  # Will be filled by Terragrunt
  backend "s3" {}

  required_version = ">= 0.12, < 0.13"
}

# #####################################
#             IAM
# #####################################
# IAM user policy
# resource "aws_iam_policy" "this" {
#    policy = file("iam_user_policy.json")
# }

# #####################################
# AWS provider
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = var.key-name
  region                  = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.1"
}

# #####################################
# AZs - Availability Zones
# Declare the Availability Zones data source
# Accessed by an AWS Account within the Region configured in the Provider
data "aws_availability_zones" "this" {
  state = "available"
}

# #####################################
# VPC (Custom Cloud)
# #####################################
resource "aws_vpc" "this" {
  cidr_block = var.cidr-vpc
  # to use DNS names of the created instances in AWS CLI
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = format("%s", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# IGW (Internet Gateway)
# #####################################
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = format("%s-igw", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# PUBLIC Subnets
# #####################################
resource "aws_subnet" "public-subnet" {
  count = length(var.public-subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = element(concat(var.public-subnets, [""]), count.index)
  availability_zone = element(data.aws_availability_zones.this.names, count.index)

  # assign public and private IPs for every instance in subnet
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = format(
        "%s-${var.public-subnet-prefix}-%s",
        var.cluster-name,
        element(data.aws_availability_zones.this.names, count.index),
      )
    },
    var.tags,
  )
}

# #####################################
# Route Table (public)
# #####################################
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.cidr-all
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name = format("%s-${var.public-subnet-prefix}-rtb", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# Associate Subnets with a PUBLIC Route Table
# #####################################
resource "aws_route_table_association" "public-rta" {
  count = length(var.public-subnets)

  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
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

# #####################################
# NAT GW
# #####################################
# Create NAT gateway (elastic) on first PUBLIC subnet
resource "aws_nat_gateway" "infra-nat-gw" {
  count = var.create-private-subnets ? 1 : 0

  allocation_id = aws_eip.this[count.index].id
  subnet_id     = aws_subnet.public-subnet[0].id

  depends_on    = [aws_internet_gateway.this]
}

# #####################################
# Private subnets
# #####################################
resource "aws_subnet" "private-subnet" {
  count = length(var.private-subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = element(concat(var.private-subnets, [""]), count.index)
  availability_zone = element(data.aws_availability_zones.this.names, count.index)

  # don't assign public IPs to the instances in subnet
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = format(
        "%s-${var.private-subnet-prefix}-%s",
        var.cluster-name,
        element(data.aws_availability_zones.this.names, count.index),
      )
    },
    var.tags,
  )
}

# #####################################
# PRIVATE Route Table with elastic IPs
# #####################################
resource "aws_route_table" "private-rtb" {
  count  = var.create-private-subnets ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = var.cidr-all
    nat_gateway_id = aws_nat_gateway.infra-nat-gw[count.index].id
  }

  tags = merge(
    {
      Name = format("%s-${var.private-subnet-prefix}-rtb", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# Associate Subnets with a PRIVATE Route Table
# #####################################
resource "aws_route_table_association" "private-rta" {
  count = length(var.private-subnets)

  subnet_id      = element(aws_subnet.private-subnet.*.id, count.index)
  route_table_id = aws_route_table.private-rtb[0].id
}
