## S3 bucket component ##

### Amazon S3 (Simple Storage Service) ###
- managed service on AWS
- never loose your data
- supports encryption (AES-256, SSL to read/write data)
- supports versioning
- fitting into free tier

### Notes ##
- Use S3 (Amazon managed file store) as Remote State Storage for Terraform
- S3 is eventually consistent

In the project I isolate VPC, DB, and Web state files and save them into S3 bucket.

### DynamoDB ###
- to avoid race conditions when 2 developers are using Terraform at the same time on the same state files
- to lock Terraform state files during deployment

### AWS Resources ###
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/s3_dynamodb.png "AWS Resources")
