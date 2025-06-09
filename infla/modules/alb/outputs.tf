// Outputs for alb (e.g., ALB DNS, Target Group ARN, etc.)
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.alb.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.alb.arn
}

output "target_group_arn" {
  description = "The ARN of the Target Group."
  value       = aws_lb_target_group.alb_tg.arn
}

output "asg_name" {
  description = "The name of the Auto Scaling Group."
  value       = aws_autoscaling_group.asg.name
}

output "launch_template_id" {
  description = "The ID of the Launch Template."
  value       = aws_launch_template.lt_web.id
}