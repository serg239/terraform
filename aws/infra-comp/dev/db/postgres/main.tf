#
# Database on public subnet group
#
terraform {
  # Will be filled by Terragrunt
  backend "s3" {}

  required_version = ">= 0.12, < 0.13"
}

# #####################################
# AWS provider
# #####################################
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "aws-db-user"
  region                  = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.1"
}

# #####################################
# VPC Remote state:
#   azs, vpc_id (vpc_igw)
# #####################################
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = var.bucket-name
    key    = "dev/vpc/terraform.tfstate"
    region = var.aws-region
  }
}

# #####################################
# Database subnets in Availability Zones
# #####################################
resource "aws_subnet" "database-subnet" {
  count = var.create-db-network ? length(var.database-subnets) : 0

  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc-id
  cidr_block        = var.database-subnets[count.index]
  availability_zone = element(data.terraform_remote_state.vpc.outputs.azs, count.index)
  # assign public and private IPs for every instance in subnet
  map_public_ip_on_launch = true

  tags = merge(
    {
      "Name" = format(
        "%s-${var.database-subnet-prefix}-%s",
        var.cluster-name,
        element(data.terraform_remote_state.vpc.outputs.azs, count.index),
      )
    },
    var.tags,
  )
}

# #####################################
# DB Route Table (assign to IGW, public)
# #####################################
resource "aws_route_table" "database-rtb" {
  count = var.create-db-network ? 1 : 0

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc-id

  route {
    cidr_block = var.cidr-all
    gateway_id = data.terraform_remote_state.vpc.outputs.vpc-igw
  }

  tags = merge(
    {
      "Name" = "${var.cluster-name}-${var.database-subnet-prefix}"
    },
    var.tags,
  )
}

# #####################################
# Associate Subnets with a DB Route Table
# #####################################
resource "aws_route_table_association" "database-rta" {
  count = var.create-db-network ? length(var.database-subnets) : 0

  subnet_id = element(aws_subnet.database-subnet.*.id, count.index)
  route_table_id = aws_route_table.database-rtb[0].id
}

# #####################################
# SG for DB instance
# #####################################
resource "aws_security_group" "rds-sg" {
  name        = "${var.cluster-name}-rds-sg"
  description = "RDS security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc-id

  ingress {
    description = "SSH access from client"
    from_port   = var.ssh-22-port
    to_port     = var.ssh-22-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr-client]
  }

  # TODO: Keep the instance private by only allowing traffic from the web server
  ingress {
    description = "Temporary DB access from anywhere"
    from_port   = var.database-5432-port
    to_port     = var.database-5432-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  # Allow all outbound traffic (IGW)
  egress {
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-all]
  }

  tags = merge(
    {
      Name = format("%s-rds-sg", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# DB Subnet Group
# #####################################
resource "aws_db_subnet_group" "public-subnet-group" {
  count       = var.create-db-network ? 1 : 0
  name        = "${var.cluster-name}-db-subnet-group"
  description = "DB subnet group"
  subnet_ids  = flatten([aws_subnet.database-subnet.*.id])

  tags = merge(
    {
      Name = format("%s-db-subnet-group", var.cluster-name)
    },
    var.tags,
  )
}

resource "aws_db_subnet_group" "private-subnet-group" {
  count       = var.create-db-network ? 0 : 1
  name        = "${var.cluster-name}-db-subnet-group"
  description = "DB subnet group"
  subnet_ids  = flatten([data.terraform_remote_state.vpc.outputs.private-subnets])

  tags = merge(
    {
      Name = format("%s-db-subnet-group", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# PG Database instance on RDS
# #####################################
resource "aws_db_instance" "pg-database" {
  identifier             = var.rds-identifier
  allocated_storage      = var.rds-storage-size
  storage_type           = var.rds-storage-type
  engine                 = var.rds-engine
  engine_version         = var.rds-engine-version
  instance_class         = var.rds-instance-class
  port                   = var.database-5432-port
  username               = var.database-username
  password               = var.database_password        # TF_VAR_database_password
  db_subnet_group_name   = [element(concat(aws_db_subnet_group.public-subnet-group.*.id, [""]), 0),
                            element(concat(aws_db_subnet_group.private-subnet-group.*.id, [""]), 0)][0]

  # element(concat(var.public-subnets, [""]), count.index)
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = var.create-db-network    # true if public subnet
  # multi_az               = true

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }

  tags = merge(
    {
      Name = format("%s-pg-db-instance", var.cluster-name)
    },
    var.tags,
  )
}
