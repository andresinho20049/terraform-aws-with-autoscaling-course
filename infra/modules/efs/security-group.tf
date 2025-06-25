# --- EFS Security Group ---
resource "aws_security_group" "efs_sg" {
  name        = "${var.account_username}.${var.region}.efs-sg.${var.environment}"
  description = "Allow NFS traffic to EFS"
  vpc_id      = var.vpc_id 

  ingress {
    from_port   = 2049 # NFS port
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [var.private_sg_id] 
    description = "Allow NFS access from EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.efs-sg.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}