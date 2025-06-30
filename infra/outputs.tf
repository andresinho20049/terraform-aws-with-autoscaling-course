output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.web_alb.alb_dns_name
}

output "asg_name" {
    description = "The name of the Auto Scaling Group."
    value       = module.web_alb.asg_name
}

output "vpc_name" {
    description = "The name of the VPC."
    value       = module.main_vpc.vpc_name
}

output "bastion_instance_id" {
    description = "The ID of the bastion host instance."
    value       = var.create_bastion_host ? module.bastion_host[0].bastion_instance_id : null
}

output "bhc_temp_bucket_name" {
  description = "The name of the S3 bucket for bastion temp files."
    value       = var.create_bastion_host ? module.bastion_host[0].bhc_temp_bucket_name : null
}