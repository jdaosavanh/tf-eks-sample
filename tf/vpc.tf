resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = local.default_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet ${count.index}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.default_name}-eks-cluster" = "owned"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public-subnet ${count.index}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.default_name}-eks-cluster" = "owned"
  }
}

resource "aws_route_table" "private-rt" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private-route" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default.id
}

resource "aws_route_table" "public-rt" {
  count = length(var.public_subnet_cidr_blocks)
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public-route" {
  count = length(var.public_subnet_cidr_blocks)
  route_table_id         = aws_route_table.public-rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private-rt[count.index].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public-rt[count.index].id
}


#
# NAT resources
#
resource "aws_eip" "nat" {

}

resource "aws_nat_gateway" "default" {
  depends_on = [aws_internet_gateway.igw]
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
}