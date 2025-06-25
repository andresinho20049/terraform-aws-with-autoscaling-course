# Defines the public and private route tables and their associations with subnets.
resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id # Reference IGW from igw.tf
  }

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.rt.public.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc, aws_internet_gateway.igw ]
}

resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.my_vpc.id

  # No default route for internet access in private subnets.
  # NAT Gateway or VPC Endpoints would be added here if needed.

  tags = {
    Name        = "${var.account_username}.${var.region}.${var.vpc_name}.rt.private.${var.environment}"
    environment = var.environment
    project     = var.project
    region      = var.region
  }

  depends_on = [ aws_vpc.my_vpc ]
}

# --- Route Table Associations ---
resource "aws_route_table_association" "rt_public_associations" {
  for_each       = aws_subnet.sub_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt_public.id

  depends_on = [ aws_route_table.rt_public, aws_subnet.sub_public ]
}

resource "aws_route_table_association" "rt_private_associations" {
  for_each       = aws_subnet.sub_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt_private.id

  depends_on = [ aws_route_table.rt_private, aws_subnet.sub_private ]
}