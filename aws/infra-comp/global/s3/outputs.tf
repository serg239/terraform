# Amazon Resource Name for S3 backet
output "s3-bucket-arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "dynamodb-table-name" {
 description = "The name of the DynamoDB table"
 value       = aws_dynamodb_table.this.name
}
