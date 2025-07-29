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

variable "public_subnet_ids" {
  description = "A list of public subnet IDs for the ALB."
  type        = list(string)
}

variable "public_sg_id" {
  description = "The ID of the public security group for the ALB."
  type        = string
}

variable "efs_sg_id" {
  description = "The ID of the security group for the ALB."
  type        = string
}

variable "bastion_sg_id" {
  description = "The ID of the security group for the bastion host."
  type        = string
}

# --- EFS Module Outputs (Inputs to this module) ---
variable "efs_id" {
  description = "The ID of the EFS file system to be mounted on the instances."
  type        = string
}

variable "efs_file_system_arn" {
  description = "The ARN of the EFS file system to be mounted on the instances."
  type        = string
}

# --- Bastion Host Variables ---
variable "instance_type" {
  description = "The EC2 instance type for the Auto Scaling Group (e.g., 't2.micro')."
  type        = string
}

variable "ami_data_id" {
  description = "The AMI ID to use for the bastion host."
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to use for the bastion host."
  type        = string
}