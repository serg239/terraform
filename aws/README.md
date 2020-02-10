# Terraform: Deployment (IaC) on AWS

This repo contains HCL (Terraform) code to deploy AWS services in custom VPC.

## Prerequisites ##
  1. Have AWS CLI installed and AWS account configured with secret keys
  2. A key pair for EC2 instances (SSH connect)

# Projects #

## web-ec2 ## 
Create simple Web server on EC2 instance.<br>
Resources:
* IAM
* VPC:
  * IGW
  * RTB
  * Public/Private subnets in AZs
  * EIP
  * NAT GW
* AMI
* SG
* EC2
  * Data source for user_data shell script

Note: the graph (as .png file) is in the web-ec2/graph directory.

## Common steps to run projects ##

* $ terrafotrm init
* $ terraform validate
* $ terraform plan
* $ terraform apply
* $ terraform destroy

## License

This code is released under the MIT License. See LICENSE.txt.
