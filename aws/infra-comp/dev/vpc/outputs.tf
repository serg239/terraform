# #####################################
# VPC
# #####################################
output "azs" {
  description = "A list of availability zones for account's region"
  value       = data.aws_availability_zones.this.names
}

output "vpc-id" {
  description = "VPC ID for references"
  value = aws_vpc.this.id
}

output "vpc-igw" {
  description = "The ID of the VPC Internet Gateway"
  value       = aws_internet_gateway.this.id
}

output "vpc-cidr-block" {
  description = "The CIDR block of the VPC"
  value       = concat(aws_vpc.this.*.cidr_block, [""])[0]
}

# #####################################
# Public Subnets
# #####################################
output "public-subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public-subnet.*.id
}

output "public-subnets-cidr-blocks" {
  description = "List of cidr-blocks of public subnets"
  value       = aws_subnet.public-subnet.*.cidr_block
}

# #####################################
# Private Subnets
# #####################################
output "private-subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private-subnet.*.id
}

output "private-subnets-cidr-blocks" {
  description = "List of cidr-blocks of private subnets"
  value       = aws_subnet.private-subnet.*.cidr_block
}
