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

variable "private_subnet_ids" {
  description = "A list of private subnet IDs for the Auto Scaling Group instances."
  type        = list(string)
}

variable "public_sg_id" {
  description = "The ID of the public security group for the ALB."
  type        = string
}

variable "private_sg_id" {
  description = "The ID of the private security group for ASG instances."
  type        = string
}

# --- ALB Specific Variables ---
variable "alb_name_suffix" {
  description = "A suffix for the ALB name (e.g., 'web-app')."
  type        = string
  default     = "lb-web"
}

variable "alb_port" {
  description = "The port for the ALB listener (e.g., 80 for HTTP, 443 for HTTPS)."
  type        = number
  default     = 80
}

variable "alb_protocol" {
  description = "The protocol for the ALB listener (e.g., 'HTTP', 'HTTPS')."
  type        = string
  default     = "HTTP"
}

# --- Target Group Specific Variables ---
variable "target_group_port" {
  description = "The port on the target instances where the application is listening."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "The protocol to use for routing traffic to the targets."
  type        = string
  default     = "HTTP"
}

variable "health_check_path" {
  description = "The destination for the health check request."
  type        = string
  default     = "/"
}

# --- Launch Template Specific Variables ---
variable "ami_name_base_prefix" {
  description = "The base prefix for the AMI name used in the launch template (e.g., 'nginx-webserver-amzn2')."
  type        = string
  validation {
    condition     = length(var.ami_name_base_prefix) > 0
    error_message = "The AMI name base prefix cannot be empty."
  }
  default     = "nginx-webserver-amzn2"
}

variable "instance_type" {
  description = "The EC2 instance type for the Auto Scaling Group (e.g., 't2.micro')."
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 Key Pair to allow SSH access."
  type        = string
  default     = "" # Provide a default empty string if no key pair is desired or created elsewhere.
}

variable "user_data_script" {
  description = "User data script to run on instance launch (e.g., to install a web server)."
  type        = string
  default     = "" # Example: filebase64("scripts/install_webserver.sh")
}

# --- Auto Scaling Group Specific Variables ---
variable "desired_capacity" {
  description = "The number of EC2 instances that should be running in the Auto Scaling Group."
  type        = number
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the Auto Scaling Group."
  type        = number
  validation {
    condition     = var.min_size <= var.desired_capacity && var.min_size >= 1
    error_message = "The minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the Auto Scaling Group."
  type        = number
  validation {
    condition     = var.max_size >= var.desired_capacity && var.max_size >= var.min_size
    error_message = "The maximum size must be greater than or equal to the desired capacity and minimum size."
  }
}