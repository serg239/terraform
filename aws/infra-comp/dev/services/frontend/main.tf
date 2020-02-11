terraform {
  # Will be filled by Terragrunt
  backend "s3" {}

  required_version = ">= 0.12, < 0.13"
}

# #####################################
# AWS provider
provider "aws" {
  # Shared credentials are defined by running:
  #    aws configure --profile aws-web-user
  # and saved in ~/.aws/credentials file
  # So, define file and profile here:
  shared_credentials_file = "~/.aws/credentials"
  profile = "aws-web-user"

  # Region definition is saved in ~/.aws/config file
  region = var.aws-region

  # Allow any 2.x version of the AWS provider
  version = "~> 2.1"
}

# #####################################
# VPC Remote state:
#   azs, vpc_id, vpc_cidr_block, public-subnets
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
# DB Remote state:
#   address, port
# #####################################
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.bucket-name
    key    = "dev/db/postgres/terraform.tfstate"
    region = var.aws-region
  }
}

# #####################################
# AMI - Image for EC2 instances
# #####################################
data "aws_ami" "ubuntu-16-amd64-hvm" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

# #####################################
# SG for ELB
# #####################################
resource "aws_security_group" "elb-sg" {
  name        = "${var.cluster-name}-elb-sg"
  description = "ELB security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc-id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = var.http-80-port
    to_port     = var.http-80-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-all]
  }

  tags = merge(
    {
      Name = format("%s-elb-sg", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# SG for EC2 (Web) instances
# #####################################
resource "aws_security_group" "web-instance-sg" {
  name        = "${var.cluster-name}-web-sg"
  description = "EC2 (Web) instance security group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc-id

  ingress {
    description = "SSH access from client IP range"
    from_port   = var.ssh-22-port
    to_port     = var.ssh-22-port
    protocol    = "tcp"
    cidr_blocks = [var.cidr-all]
  }

  ingress {
    description = "HTTP access from the VPC"
    from_port   = var.http-80-port      # busybox: port 8080
    to_port     = var.http-80-port      # busybox: port 8080
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.vpc.outputs.vpc-cidr-block]
  }

  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr-all]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = format("%s-web-instance-sg", var.cluster-name)
    },
    var.tags,
  )
}

# #####################################
# Data source for EC2 (Web server on azs[0]) user_data
# #####################################
data "template_file" "nginx-blue" {
  template = file("nginx_blue.sh")
  vars = {
    cluster-name     = var.cluster-name
    database-address = data.terraform_remote_state.db.outputs.database-address
    database-port    = data.terraform_remote_state.db.outputs.database-port
  }
}

# #####################################
# Data source for EC2 (Web server on azs[1]) user_data
# #####################################
data "template_file" "nginx-green" {
  template = file("nginx_green.sh")
  vars = {
    cluster-name     = var.cluster-name
    database-address = data.terraform_remote_state.db.outputs.database-address
    database-port    = data.terraform_remote_state.db.outputs.database-port
  }
}

# #####################################
# EC2 (Web) instances
# #####################################
resource "aws_instance" "web-instance" {
  count = length(data.terraform_remote_state.vpc.outputs.azs)

  ami                    = data.aws_ami.ubuntu-16-amd64-hvm.id
  instance_type          = var.web-instance-type
  subnet_id              = element(data.terraform_remote_state.vpc.outputs.public-subnets, count.index)
  vpc_security_group_ids = [aws_security_group.web-instance-sg.id]
  key_name               = var.web-key-pair-name
  # provisioner "remote-exec" { inline = [] }
  # user_data              = data.template_file.user_data.rendered
  user_data = (
      count.index == 0 ? data.template_file.nginx-blue.rendered
                  : data.template_file.nginx-green.rendered
  )

  # associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name = format("%s-web-instance-%02d", var.cluster-name, count.index + 1)
    },
    var.tags,
  )
}

# #####################################
# Load Balancer
# #####################################
resource "aws_elb" "this" {
  name            = "${var.cluster-name}-web-elb"
  subnets         = flatten([data.terraform_remote_state.vpc.outputs.public-subnets])
  security_groups = [aws_security_group.elb-sg.id]
  instances       = flatten([aws_instance.web-instance.*.id])

  listener {
    lb_port           = var.http-80-port
    lb_protocol       = "http"
    instance_port     = var.http-80-port    # nginx: port 80; busybox: port 8080
    instance_protocol = "http"
  }

  # target could be "HTTP:8080/"" or "HTTP:8080/index.html" or "TCP:8080"
  health_check {
    target              = "HTTP:${var.http-80-port}/"    # nginx
    # target            = "HTTP:${var.http-8080-port}/"  # busybox
    timeout             = 5
    interval            = 30
    unhealthy_threshold = 2
    healthy_threshold   = 10
  }

  tags = merge(
    {
      Name = format("%s-elb", var.cluster-name)
    },
    var.tags,
  )
}
