# --- General Project Variables (Passed from Root) ---
variable "account_username" {
  description = "The username or identifier for resource naming convention."
  type        = string
}

variable "region" {
  description = "The AWS region where this specific VPC will be provisioned."
  type        = string
}

variable "environment" {
  description = "The environment (e.g., 'dev', 'prod', 'staging') for resource tagging and naming."
  type        = string
}

variable "project" {
  description = "The project name for resource tagging."
  type        = string
}

# --- VPC Specific Variables ---
variable "vpc_name" {
  description = "A unique name suffix for this VPC (e.g., 'main', 'peering-target')."
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for this VPC (e.g., '10.0.0.0/16' or '10.1.0.0/16')."
  type        = string
}

# --- Subnet CIDR Blocks for this VPC ---
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets in this VPC (e.g., ['10.0.1.0/24', '10.0.3.0/24'])."
  type        = list(string)
  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/([0-9]|[12][0-9]|3[0-2])$", cidr))])
    error_message = "One or more provided public subnet CIDRs are not in a valid IPv4 CIDR format (e.g., '10.0.1.0/24')."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets in this VPC (e.g., ['10.0.2.0/24', '10.0.4.0/24'])."
  type        = list(string)
  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\/([0-9]|[12][0-9]|3[0-2])$", cidr))])
    error_message = "One or more provided private subnet CIDRs are not in a valid IPv4 CIDR format (e.g., '10.0.2.0/24')."
  }
}

# --- AZ Suffixes for Subnets ---
variable "public_azs" {
  description = "List of Availability Zone suffixes for public subnets (e.g., ['a', 'b']). Must match count of public_subnet_cidrs."
  type        = list(string)
  validation {
    condition     = length(var.public_azs) == length(var.public_subnet_cidrs)
    error_message = "The number of 'public_azs' must match the number of 'public_subnet_cidrs'."
  }
  validation {
    condition     = alltrue([for az_suffix in var.public_azs : can(regex("^[a-z]$", az_suffix))])
    error_message = "Public AZ suffixes must be single lowercase letters (e.g., 'a', 'b')."
  }
}

variable "private_azs" {
  description = "List of Availability Zone suffixes for private subnets (e.g., ['a', 'b']). Must match count of private_subnet_cidrs."
  type        = list(string)
  validation {
    condition     = length(var.private_azs) == length(var.private_subnet_cidrs)
    error_message = "The number of 'private_azs' must match the number of 'private_subnet_cidrs'."
  }
  validation {
    condition     = alltrue([for az_suffix in var.private_azs : can(regex("^[a-z]$", az_suffix))])
    error_message = "Private AZ suffixes must be single lowercase letters (e.g., 'a', 'b')."
  }
}