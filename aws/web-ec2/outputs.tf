output vpc_id {
  value = aws_vpc.web-ec2.id
}

output "public_ip" {
  value = aws_instance.web-ec2.public_ip
}

output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = aws_instance.web-ec2.public_dns
}
