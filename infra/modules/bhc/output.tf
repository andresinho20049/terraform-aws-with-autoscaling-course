# Outputs for the Bastion Host module
output "bastion_instance_id" {
  description = "The ID of the created bastion host instance."
  value       = aws_instance.bastion.id
}

output "bhc_temp_bucket_name" {
  description = "The name of the S3 bucket for bastion temp files."
  value       = aws_s3_bucket.bhc_temp.bucket
}