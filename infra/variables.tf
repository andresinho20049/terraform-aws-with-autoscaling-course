variable "account_username" {
  description = "Your username for resource naming."
}

variable "region" {
  description = "AWS region for resource provisioning."
}

variable "environment" {
  description = "Deployment environment (dev, prod, staging, etc.)."
}

variable "project" {
  description = "Project name for resource tagging."
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

# --- ALB Specific Variables ---

variable "alb_name_suffix" {
  description = "A suffix for the ALB name (e.g., 'web-app')."
  type        = string
  default     = "main"
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

variable "target_group_name_suffix" {
  description = "A suffix for the Target Group name (e.g., 'web-tg')."
  type        = string
  default     = "web"
}

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
  description = "The base prefix for the AMI name (e.g., 'nginx-webserver-amzn2')."
  type        = string
  default     = "nginx-webserver-amzn2"
  validation {
    condition     = length(var.ami_name_base_prefix) > 0
    error_message = "The AMI name base prefix cannot be empty."
  }
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
  default     = 2
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 2
  validation {
    condition     = var.min_size <= var.desired_capacity && var.min_size >= 1
    error_message = "The minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 6
  validation {
    condition     = var.max_size >= var.desired_capacity && var.max_size >= var.min_size
    error_message = "The maximum size must be greater than or equal to the desired capacity and minimum size."
  }
}

# --- Bastion Host Specific Variables ---
variable "create_bastion_host" {
  description = "Set to 1 to create a temporary bastion host for EFS operations."
  type        = bool
  default     = false # Default to false, so it's not created unless explicitly set
}

variable "bastion_instance_type" {
  description = "The EC2 instance type for the bastion host (e.g., 't2.micro')."
  type        = string
  default     = "t2.micro"
}