# Bastion Host Controller

resource "aws_instance" "bastion" {
  ami                         = var.ami_data_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0] 
  vpc_security_group_ids      = [var.bastion_sg_id] 
  key_name                    = var.key_name
  associate_public_ip_address = true # To allow SSH and SSM access from the internet

  iam_instance_profile        = aws_iam_instance_profile.ssm_efs_profile.name 

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_file_system_id = var.efs_id
    aws_region         = var.region
  }))

  tags = {
    Name        = "${var.account_username}.${var.region}.bastion.${var.environment}"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [ aws_iam_instance_profile.ssm_efs_profile ]
}