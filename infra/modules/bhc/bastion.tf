# Bastion Host Controller

resource "aws_instance" "bastion" {
  ami                         = var.ami_data_id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0] 
  vpc_security_group_ids      = [var.bastion_sg_id] 
  key_name                    = var.key_name
  associate_public_ip_address = true

  iam_instance_profile        = aws_iam_instance_profile.bastion_host_profile.name

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_file_system_id = var.efs_id
    aws_region         = var.region
  }))

  tags = {
    Name        = "${var.account_username}.${var.region}.bastion.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_iam_instance_profile.bastion_host_profile ]
}