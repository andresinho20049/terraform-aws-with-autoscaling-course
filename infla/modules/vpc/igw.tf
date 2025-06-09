# Defines the Internet Gateway for the VPC.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.igw.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc ]
}