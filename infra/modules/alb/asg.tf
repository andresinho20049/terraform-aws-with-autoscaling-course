# --- Auto Scaling Group ---
resource "aws_autoscaling_group" "asg" {
  name                 = "${var.account_username}.${var.region}.asg.${var.environment}"
  vpc_zone_identifier  = var.private_subnet_ids # ASG instances deploy into private subnets
  desired_capacity     = var.desired_capacity
  min_size             = var.min_size
  max_size             = var.max_size
  target_group_arns    = [aws_lb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.lt_web.id
    version = "$Latest" # Always use the latest version of the Launch Template
  }

  tag {
    key                 = "Name"
    value               = "${var.account_username}.${var.region}.asg.${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "project"
    value               = var.project
    propagate_at_launch = true
  }

  tag {
    key                 = "region"
    value               = var.region
    propagate_at_launch = true
  }
  
  depends_on = [ aws_lb_target_group.alb_tg, aws_launch_template.lt_web ]
}

# Auto Scaling Policies (e.g., CPU utilization)
resource "aws_autoscaling_policy" "cpu_scaling_up" {
  name                   = "${var.account_username}.${var.region}.asg.cpu-scaling-up.${var.environment}"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Target 70% CPU utilization
  }

  depends_on = [ aws_autoscaling_group.asg ]
  
}