# --- EFS File System ---
resource "aws_efs_file_system" "efs_file_system" {
  creation_token = "${var.account_username}.${var.region}.efs.${var.environment}"
  performance_mode = "generalPurpose" # Free tier eligible
  throughput_mode  = "elastic"

  tags = {
    Name        = "${var.account_username}.${var.region}.efs.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

# --- EFS Mount Targets ---
resource "aws_efs_mount_target" "efs_file_system_mount_target" {
  count          = length(var.private_subnet_ids) # Create a mount target for each private subnet
  file_system_id = aws_efs_file_system.efs_file_system.id
  subnet_id      = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]

  depends_on = [aws_efs_file_system.efs_file_system]
}