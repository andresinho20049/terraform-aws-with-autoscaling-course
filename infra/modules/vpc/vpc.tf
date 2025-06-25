resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

# Define a local to easily map subnet CIDRs to AZ suffixes
locals {
  public_subnets_config = {
    for i, cidr in var.public_subnet_cidrs :
    "az-${var.public_azs[i]}-${i}" => { 
      cidr_block = cidr
      az_suffix  = var.public_azs[i]
    }
  }

  private_subnets_config = {
    for i, cidr in var.private_subnet_cidrs :
    "az-${var.private_azs[i]}-${i}" => { 
      cidr_block = cidr
      az_suffix  = var.private_azs[i]
    }
  }
}