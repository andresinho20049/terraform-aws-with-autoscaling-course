output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = module.alb.alb_dns_name
}

output "vpc_name" {
    description = "The name of the VPC."
    value       = module.vpc.vpc_name
}