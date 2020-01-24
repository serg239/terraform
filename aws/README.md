# Terraform: Deployment (IaC) on AWS

This repo contains HCL (Terraform) code to deploy AWS services in custom VPC.

## Prerequisites ##
  1. Have AWS CLI installed and AWS account configured with secret keys
  2. A key pair for EC2 instances (SSH connect)

# Projects #

## web-ec2 ## 
Create simple Web server on EC2 instance in custom VPC.

## Common steps to run projects ##

$ terrafotrm init
$ terraform validate
$ terraform plan
$ terraform apply
$ terraform destroy

## License

This code is released under the MIT License. See LICENSE.txt.
