# Defines security groups for public and private resources within the VPC.
resource "aws_security_group" "sg_public" {
  name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.public.${var.environment}"
  description = "Allow SSH and HTTP access to public resources in ${var.vpc_name} VPC"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.public.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc ]
}

resource "aws_security_group" "sg_private" {
  name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.private.${var.environment}"
  description = "Allow SSH access from within ${var.vpc_name} VPC subnets"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH from within VPC CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.my_vpc.cidr_block] # Allow SSH from any instance within this VPC's CIDR
  }

  ingress {
    description = "HTTP from public security group"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.private.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc, aws_security_group.sg_public ]
}

# Defines a security group for the bastion host.
resource "aws_security_group" "sg_bastion" {
  name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.bastion.${var.environment}"
  description = "Security group for the bastion host, access via SSM"
  vpc_id      = aws_vpc.my_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.bastion.${var.environment}"
    Project     = var.project
    Environment = var.environment
  }
}

# --- EFS Security Group ---
resource "aws_security_group" "sg_efs" {
  name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.efs.${var.environment}"
  description = "Allow NFS traffic to EFS"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 2049 # NFS port
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_private.id, aws_security_group.sg_bastion.id] # Allow access from private subnets and bastion host
    description = "Allow NFS access from EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.efs.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }
}