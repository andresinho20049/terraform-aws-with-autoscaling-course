variable "aws_region" {
  type    = string
  default = "sa-east-1"
  validation {
    condition     = contains(["us-east-1", "us-east-2", "us-west-1", "sa-east-1"], var.aws_region)
    error_message = "Invalid AWS region. Choose from 'us-east-1', 'us-east-2', 'us-west-1', or 'sa-east-1'."
  }
}

variable "ami_name_base_prefix" {
  type    = string
  default = "httpd-webserver-amzn2"
  validation {
    condition     = length(var.ami_name_base_prefix) > 0
    error_message = "The AMI name base prefix cannot be empty."
  }
}

variable "instance_type" {
  type    = string
  default = "t2.micro"

  # if environment is dev, restrict to t2.micro only
  validation {
    condition     = var.environment == "dev" ? var.instance_type == "t2.micro" : contains(["t2.micro", "t3.micro", "t3.medium"], var.instance_type)
    error_message = "For dev environment, the instance type must be t2.micro. For other environments, it can be t2.micro, t3.micro, or t3.medium."
  }
}

variable "environment" {
  type        = string
  description = "The environment for which the AMI is being built (e.g., dev, prod, staging)."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Invalid environment. Choose from 'dev', 'staging', or 'prod'."
  }
}

variable "username" {
    type        = string
    description = "The username for the AMI build."
    default     = "ec2-user"
    validation {
        condition     = length(var.username) > 0
        error_message = "The username cannot be empty."
    }
}