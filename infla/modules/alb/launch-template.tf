# --- Launch Template ---
resource "aws_launch_template" "lt_web" {
  name   = "${var.account_username}.${var.region}.lt.${var.environment}"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name # Can be empty if no key pair is desired

  network_interfaces {
    associate_public_ip_address = false # Instances in private subnets should NOT have public IPs
    security_groups             = [var.private_sg_id] # Instances use the private SG
  }

  user_data = var.user_data_script # Base64 encoded user data script

  block_device_mappings {
    device_name = "/dev/xvda" # Adjust based on AMI, common for Linux
    ebs {
      volume_size = 8 # GB
      volume_type = "gp2"
      delete_on_termination = true
    }
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.lt.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}