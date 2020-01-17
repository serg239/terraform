output vpc_id {
  value = aws_vpc.paws-vpc.id
}

output "public_ip" {
  value = aws_instance.tf-ec2-ebs-micro.public_ip
}
