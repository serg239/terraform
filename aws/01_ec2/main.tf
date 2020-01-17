terraform {
  required_version = ">= 0.12, < 0.13"
}

# =====================================
# Set a Provider
# =====================================
provider "aws" {
  region = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.0"
}

# =====================================
# VPC (not default)
# Create: 
#   Default subnet in each Availability Zone 
#   Internet Gateway 
#   Route table with a route to the Internet Gateway
# =====================================
resource "aws_vpc" "paws-vpc" {
  cidr_block = var.vpc-cidr
  # enable_dns_hostnames = true
  # enable_dns_support = true

  tags = {
    Name = var.vpc-name
  }
}

# =====================================
# 2. Create an Internet Gateway
# =====================================
resource "aws_internet_gateway" "paws-internet-gw" {
  vpc_id = aws_vpc.paws-vpc.id
}

# =====================================
# 3. Create NAT Gateway
# =====================================
resource "aws_eip" "nat-eip" {
  vpc = true
}

resource "aws_nat_gateway" "paws-nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id = aws_subnet.us-west-1b-public.id
  depends_on = [aws_internet_gateway.paws-internet-gw]
}

# =====================================
# 3. Create Public and Private ROUTE TABLES
# =====================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.paws-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.paws-internet-gw.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.paws-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.paws-nat-gw.id
  }

  tags = {
    Name = "Private"
  }
}

# =====================================
# Create and associate PUBLIC SUBNETS with a Route table
# =====================================
#
# us-west-1b-public subnet
#
resource "aws_subnet" "us-west-1b-public" {
  vpc_id = aws_vpc.paws-vpc.id
  cidr_block = cidrsubnet(var.vpc-cidr, 8, 1)
  availability_zone = element(split(",", var.aws-availability-zones), 0)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public"
  }
}


resource "aws_route_table_association" "us-west-1b-public" {
  subnet_id = aws_subnet.us-west-1b-public.id
  route_table_id = aws_route_table.public.id
}

#
# us-west-1c-public subnet
#
resource "aws_subnet" "us-west-1c-public" {
  vpc_id = aws_vpc.paws-vpc.id
  cidr_block = cidrsubnet(var.vpc-cidr, 8, 3)
  availability_zone = element(split(",", var.aws-availability-zones), 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table_association" "us-west-1c-public" {
  subnet_id = aws_subnet.us-west-1c-public.id
  route_table_id = aws_route_table.public.id
}

# =====================================
# Create and associate PRIVATE SUBNETS with a route table
# =====================================
#
# us-west-1b-private subnet
#
resource "aws_subnet" "us-west-1b-private" {
  vpc_id = aws_vpc.paws-vpc.id
  cidr_block = cidrsubnet(var.vpc-cidr, 8, 2)
  availability_zone = element(split(",", var.aws-availability-zones), 0)
  map_public_ip_on_launch = false

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "us-west-1b-private" {
  subnet_id = aws_subnet.us-west-1b-private.id
  route_table_id = aws_route_table.private.id
}

#
# us-west-1c-private subnet
#
resource "aws_subnet" "us-west-1c-private" {
  vpc_id = aws_vpc.paws-vpc.id
  cidr_block = cidrsubnet(var.vpc-cidr, 8, 4)
  availability_zone = element(split(",", var.aws-availability-zones), 1)
  map_public_ip_on_launch = false

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "us-west-1c-private" {
  subnet_id = aws_subnet.us-west-1c-private.id
  route_table_id = aws_route_table.private.id
}

# =====================================
# Security Group
# to receive incoming TCP requests on port 8080
# from the CIDR block (IP address range) 0.0.0.0/0 - from any IPs
# =====================================

resource "aws_security_group" "paws-sg-ec2" {
  name = "paws-sg-ec2"
  description = "EC2 security group"
  vpc_id = aws_vpc.paws-vpc.id

  ingress {
    from_port = var.ec2-port
    to_port = var.ec2-port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### EC2 ###
resource "aws_instance" "tf-ec2-ebs-micro" {
  ami           = var.ec2-image-id
  instance_type = var.ec2-instance-type
  # vpc_security_group_ids = [aws_security_group.paws-sg-ec2.id] 
  subnet_id = aws_subnet.us-west-1b-public.id

  user_data = <<-EOF
      #!/bin/bash
      echo "Hello, World!" > index.html
      nohup busybox httpd -f -p 8080 &
      EOF

  tags = {
    Name = "tf-ec2-ebs"
  }
}
