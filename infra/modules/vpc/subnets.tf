# Defines the public and private subnets for the VPC.
resource "aws_subnet" "sub_public" {
  for_each          = local.public_subnets_config # Reference local from main.tf
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${var.region}${each.value.az_suffix}"
  map_public_ip_on_launch = true # Typically true for public subnets

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.subnet.public-${each.key}.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc ]
}

resource "aws_subnet" "sub_private" {
  for_each          = local.private_subnets_config # Reference local from main.tf
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${var.region}${each.value.az_suffix}"

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.subnet.private-${each.key}.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc ]
}