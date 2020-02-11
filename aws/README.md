# Terraform: Deployment (IaC) on AWS

This repo contains HCL (Terraform) code to deploy AWS services in custom VPC.

## Prerequisites ##
  1. Have AWS CLI installed and AWS account configured with secret keys
  2. A key pair for EC2 instances
  3. Shared credentials are defined by running:
``` bash
  $ aws configure --profile <key-name>
```
and saved in ~/.aws/credentials file.

The Region definition is saved in ~/.aws/config file.
 
# Projects #

## Simple Web server: [infra-ec2](https://github.com/serg239/terraform/blob/master/aws/infra-ec2)
## DB/Web servers with shared storage of state files on S3 bucket: [infra-comp](https://github.com/serg239/terraform/blob/master/aws/infra-comp)
