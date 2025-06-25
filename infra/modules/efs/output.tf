# generate output for the EFS file system ID
output "efs_file_system_id" {
  description = "The ID of the EFS file system created for NGINX content."
  value       = aws_efs_file_system.efs_file_system.id
}   

# generate output for the EFS security group ID
output "efs_security_group_id" {
  description = "The ID of the security group associated with the EFS file system."
  value       = aws_security_group.efs_sg.id
}