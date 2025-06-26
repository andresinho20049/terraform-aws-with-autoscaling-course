# IAM Role for SSM and EFS Client Access
resource "aws_iam_role" "ssm_efs_role" {
  name = "${var.account_username}.${var.region}.iam.ssm-efs-role.${var.environment}"
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
    Name        = "${var.account_username}.${var.region}.iam.ssm-efs-role.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.ssm_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for EFS Client Access
# This policy allows EC2 instances to mount and write to EFS file systems.
resource "aws_iam_policy" "efs_client_policy" {
  name        = "${var.account_username}.${var.region}.iam-policy.efs-client-olicy.${var.environment}"
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

resource "aws_iam_role_policy_attachment" "efs_client_policy_attachment" {
  role       = aws_iam_role.ssm_efs_role.name
  policy_arn = aws_iam_policy.efs_client_policy.arn
}


resource "aws_iam_instance_profile" "ssm_efs_profile" {
  name = "${var.account_username}.${var.region}.iam-instance-profile.ssm-efs-profile.${var.environment}"
  role = aws_iam_role.ssm_efs_role.name

  tags = {
    Name        = "${var.account_username}.${var.region}.iam-instance-profile.ssm-efs-profile.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}
