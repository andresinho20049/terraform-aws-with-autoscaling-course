output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.web_alb.alb_dns_name
}

output "vpc_name" {
    description = "The name of the VPC."
    value       = module.main_vpc.vpc_name
}