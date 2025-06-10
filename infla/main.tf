// This file orchestrates the Terraform modules for AWS infrastructure.

module "main_vpc" {
  source               = "./modules/vpc"

  vpc_name             = var.vpc_name
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  public_azs           = var.public_azs
  private_azs          = var.private_azs

  account_username     = var.account_username
  region               = var.region
  environment          = var.environment
  project              = var.project
}

module "web_alb" {
  source = "./modules/alb"

  # Pass outputs from the main_vpc module as inputs
  vpc_id              = module.main_vpc.vpc_id
  public_subnet_ids   = module.main_vpc.public_subnet_ids
  private_subnet_ids  = module.main_vpc.private_subnet_ids
  public_sg_id        = module.main_vpc.public_security_group_id
  private_sg_id       = module.main_vpc.private_security_group_id 

  # ALB & Target Group configuration
  alb_name_suffix      = var.alb_name_suffix
  alb_port             = var.alb_port
  alb_protocol         = var.alb_protocol
  target_group_port    = var.target_group_port
  target_group_protocol = var.target_group_protocol
  health_check_path    = var.health_check_path
  
  # Launch Template configuration
  ami_id               = var.ami_id 
  instance_type        = var.instance_type 
  key_name             = var.key_name
  user_data_script     = filebase64("./envs/${var.environment}/start_script.sh") 

  # Auto Scaling Group configuration
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size

  account_username = var.account_username
  region           = var.region 
  environment      = var.environment
  project          = var.project

  depends_on = [ module.main_vpc ]
}
