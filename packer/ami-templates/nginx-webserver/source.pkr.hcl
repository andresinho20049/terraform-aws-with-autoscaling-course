source "amazon-ebs" "nginx_webserver" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "${var.ami_name_base_prefix}-${var.environment}-${formatdate("YYYYMMDDHHMM", timestamp())}"
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ssh_username = "ec2-user"
  ami_description = "AMI for Nginx Web Server in ${var.environment} environment, built on ${formatdate("YYYY-MM-DD HH:mm:ss", timestamp())}"
  
  tags = {
    Name        = "${var.ami_name_base_prefix}-${var.environment}-packer-build"
    Environment = var.environment
    ManagedBy   = "Packer"
  }
}