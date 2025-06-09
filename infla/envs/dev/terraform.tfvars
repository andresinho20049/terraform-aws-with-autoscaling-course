# Example variables for the dev environment
# account_username = "${var.account_username}"
# project          = "${var.project}"
region           = "us-east-1"
environment      = "dev"

vpc_name         = "my-vpc"
vpc_cidr_block   = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "100.0.4.0/24"]
public_azs       = ["a", "b"]
private_azs      = ["a", "b"]

instance_type    = "t2.micro"
asg_min_size     = 1
asg_max_size     = 2
asg_desired_capacity = 1
ami_id           = "ami-xxxxxxxx"