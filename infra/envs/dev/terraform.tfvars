# --- Global Project Variables ---
environment      = "dev"               # The deployment environment (e.g., 'dev', 'prod', 'staging')

# --- VPC Module Variables ---
vpc_name             = "main-vpc"
vpc_cidr_block       = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]  # CIDRs for public subnets (e.g., AZa, AZb)
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"] # CIDRs for private subnets (e.g., AZa, AZb)
public_azs           = ["a", "c"]                     # AZ suffixes for public subnets
private_azs          = ["a", "c"]                     # AZ suffixes for private subnets

# --- ALB Module Variables ---
alb_name_suffix      = "lb-web"      # A suffix for the ALB name
alb_port             = 80            # Listener port for the ALB (e.g., 80 for HTTP)
alb_protocol         = "HTTP"        # Listener protocol for the ALB (e.g., 'HTTP', 'HTTPS')
target_group_port    = 80            # Port on instances where the application listens
target_group_protocol = "HTTP"       # Protocol for target group health checks and traffic
health_check_path    = "/"           # Path for ALB health checks

# --- EC2 Instance / Launch Template Variables ---
ami_name_base_prefix = "nginx-webserver-amzn2"  # Base prefix for the AMI name 
instance_type        = "t2.micro"

# --- Auto Scaling Group Variables ---
desired_capacity     = 2  # Desired number of instances in the ASG
min_size             = 1  # Minimum number of instances in the ASG
max_size             = 3  # Maximum number of instances in the ASG