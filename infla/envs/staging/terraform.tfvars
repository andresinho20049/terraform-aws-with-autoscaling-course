# --- Global Project Variables ---
region           = "us-east-1"
environment      = "staging"

# --- VPC Module Variables ---
vpc_name             = "main-vpc"
vpc_cidr_block       = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
public_azs           = ["a", "b"]
private_azs          = ["a", "b"]

# --- ALB Module Variables ---
alb_name_suffix      = "lb-web"
alb_port             = 80
alb_protocol         = "HTTP"
target_group_port    = 80
target_group_protocol = "HTTP"
health_check_path    = "/"

# --- EC2 Instance / Launch Template Variables ---
ami_id               = "ami-0e9bbd70d26d7cf4f"
instance_type        = "t2.micro"

# --- Auto Scaling Group Variables ---
desired_capacity     = 3
min_size             = 2
max_size             = 6