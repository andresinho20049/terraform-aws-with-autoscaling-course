# --- Application Load Balancer (ALB) ---
resource "aws_lb" "alb" {
  name               = "${var.account_username}.${var.region}.alb.${var.alb_name_suffix}.${var.environment}"
  internal           = false # Publicly accessible ALB
  load_balancer_type = "application"
  security_groups    = [var.public_sg_id] # ALB uses the public SG
  subnets            = var.public_subnet_ids # ALB needs public subnets

  tags = {
    Name        = "${var.account_username}.${var.region}.alb.${var.alb_name_suffix}.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

# --- Target Group ---
resource "aws_lb_target_group" "alb_tg" {
  name        = "${var.account_username}.${var.region}.${var.alb_name_suffix}.tg.${var.environment}"
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    protocol            = var.target_group_protocol
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200" # Expect HTTP 200 OK
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.alb_name_suffix}.tg.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

# --- ALB Listener ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_port
  protocol          = var.alb_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.alb_name_suffix}.listener.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
  depends_on = [ aws_lb.alb, aws_lb_target_group.alb_tg ]
}