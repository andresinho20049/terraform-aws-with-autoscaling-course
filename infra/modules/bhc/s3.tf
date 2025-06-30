# S3 bucket para arquivos temporários do bastion host
resource "aws_s3_bucket" "bhc_temp" {
  bucket = "${var.account_username}.${var.region}.s3.bhc-temp.${var.environment}"
  force_destroy = true
  tags = {
    Name        = "${var.account_username}.${var.region}.s3.bhc-temp.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}
