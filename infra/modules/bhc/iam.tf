# IAM Role for Bastion Host (SSM, EFS, S3)
resource "aws_iam_role" "bastion_host_role" {
  name = "${var.account_username}.${var.region}.iam.bastion-host-role.${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name        = "${var.account_username}.${var.region}.iam.bastion-host-role.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

# Attach SSM Managed Policy
resource "aws_iam_role_policy_attachment" "bastion_ssm_managed_policy" {
  role       = aws_iam_role.bastion_host_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach EFS Client Policy
resource "aws_iam_policy" "efs_client_policy" {
  name        = "${var.account_username}.${var.region}.iam-policy.efs-client-policy.${var.environment}"
  description = "Allows EC2 instances to act as EFS clients"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ],
        Effect   = "Allow",
        Resource = "${var.efs_file_system_arn}"
      }
    ]
  })
  tags = {
    Name        = "${var.account_username}.${var.region}.iam-policy.efs-client-policy.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}
resource "aws_iam_role_policy_attachment" "bastion_efs_client_policy_attachment" {
  role       = aws_iam_role.bastion_host_role.name
  policy_arn = aws_iam_policy.efs_client_policy.arn
}

# Attach S3 Temp Policy
resource "aws_iam_policy" "bhc_s3_temp_access" {
  name        = "${var.account_username}.${var.region}.iam-policy.efs-s3-temp-access.${var.environment}"
  description = "Permite acesso ao bucket S3 temporário do bastion host."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bhc_temp.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bhc_temp.bucket}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "bastion_s3_temp_policy_attachment" {
  role       = aws_iam_role.bastion_host_role.name
  policy_arn = aws_iam_policy.bhc_s3_temp_access.arn
}

# Instance profile for Bastion Host
resource "aws_iam_instance_profile" "bastion_host_profile" {
  name = "${var.account_username}.${var.region}.iam-instance-profile.bastion-host-profile.${var.environment}"
  role = aws_iam_role.bastion_host_role.name
  tags = {
    Name        = "${var.account_username}.${var.region}.iam-instance-profile.bastion-host-profile.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}
