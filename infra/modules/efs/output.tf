# generate output for the EFS file system ID
output "efs_file_system_id" {
  description = "The ID of the EFS file system created for NGINX content."
  value       = aws_efs_file_system.efs_file_system.id
}   

output "efs_file_system_arn" {
  description = "The ARN of the EFS file system created for NGINX content."
  value       = aws_efs_file_system.efs_file_system.arn
}