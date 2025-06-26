# Outputs for the Bastion Host module
output "bastion_instance_id" {
  description = "The ID of the created bastion host instance."
  value       = aws_instance.bastion.id
}