# Outputs various attributes of the created VPC resources.
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.my_vpc.id
}

output "vpc_name" {
  description = "The name of the VPC."
  value       = aws_vpc.my_vpc.tags["Name"]
}

output "public_subnet_ids" {
  description = "A list of IDs for the public subnets."
  value       = [for s in aws_subnet.sub_public : s.id]
}

output "private_subnet_ids" {
  description = "A list of IDs for the private subnets."
  value       = [for s in aws_subnet.sub_private : s.id]
}

output "public_security_group_id" {
  description = "The ID of the public security group."
  value       = aws_security_group.sg_public.id
}

output "private_security_group_id" {
  description = "The ID of the private security group."
  value       = aws_security_group.sg_private.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.my_vpc.cidr_block
}