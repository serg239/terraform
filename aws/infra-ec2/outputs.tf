output vpc-id {
  value = aws_vpc.this.id
}

output "public-ip" {
  value = aws_instance.ec2-instance.public_ip
}

output "public-dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value       = aws_instance.ec2-instance.public_dns
}
