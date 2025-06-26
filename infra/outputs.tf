output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.web_alb.alb_dns_name
}

output "vpc_name" {
    description = "The name of the VPC."
    value       = module.main_vpc.vpc_name
}

output "bastion_instance_id" {
    description = "The ID of the bastion host instance."
    value       = var.create_bastion_host ? module.bastion_host[0].bastion_instance_id : null
}