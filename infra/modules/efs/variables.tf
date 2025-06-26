# --- General Project Variables (Passed from Root) ---
variable "account_username" {
  description = "The username or identifier for resource naming convention."
  type        = string
}

variable "region" {
  description = "The AWS region where this ALB will be provisioned."
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

# --- VPC Module Outputs (Inputs to this module) ---
variable "vpc_id" {
  description = "The ID of the VPC where the ALB and instances will be deployed."
  type        = string
}
variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the Auto Scaling Group instances."
  type        = list(string)
}

variable "private_sg_id" {
  description = "The ID of the private security group for ASG instances."
  type        = string
}

variable "bastion_sg_id" {
  description = "The ID of the security group for the bastion host."
  type        = string  
}

variable "efs_sg_id" {
  description = "The ID of the security group for the EFS."
  type        = string
}