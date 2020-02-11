## Environment:

### Amazon S3 (Simple Storage Service)
- managed service on AWS
- never loose your data
- supports encryption (AES-256, SSL to read/write data)
- supports versioning
- fitting into free tier

In the project I isolate VPC, DB, and Web state files and save them in the S3 bucket.

AWS Resources
-------------
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/s3_dynamodb.png "AWS Resources")
