# Defines security groups for public and private resources within the VPC.
resource "aws_security_group" "sg_public" {
  name        = "${var.account_username}.${var.region}.${var.vpc_name}.sg.public.${var.environment}"
  description = "Allow SSH and HTTP access to public resources in ${var.vpc_name} VPC"
  vpc_id      = aws_vpc.my_vpc.id
  
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  vpc_id      = aws_vpc.my_vpc.id # Reference VPC from main.tf

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