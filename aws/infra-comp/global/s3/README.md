## S3 bucket component ##

### AWS Resources ###
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/s3_dynamodb.png "AWS Resources")

### Amazon S3 (Simple Storage Service) ###
- managed service on AWS
- never loose your data
- supports encryption (AES-256, SSL to read/write data)
- supports versioning
- fitting into free tier

### DynamoDB ###
- to avoid race conditions when 2 developers are using Terraform at the same time on the same state files
- to lock Terraform state files during deployment

### Notes ###
- Use S3 (Amazon managed file store) as Remote State Storage for Terraform
- S3 is eventually consistent
- In the project I isolate VPC, DB, and Web state files and save them in S3 bucket

### terraform.tfvars (variables) ###
```hcl
aws-region     = "us-west-1"
bucket-name    = "infra-comp-bucket-serg239"
ddb-table-name = "infra-comp"
```

### Steps to deploy and destroy the component ###
```bash
$ terragrunt init
$ terragrunt validate
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true

$ terragrunt apply 2020_02_10.tfplan
Outputs:
dynamodb_table_name = infra-comp
s3_bucket_arn = arn:aws:s3:::infra-comp-bucket-serg239

$ terragrunt destroy
```
