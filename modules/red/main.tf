# MÓDULO red · VPC con una subred pública por zona y salida a Internet

resource "aws_vpc" "principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.nombre}-vpc"
  }
}

# Excepción justificada: los servidores web
# son públicos (no hay balanceador), así que
# sus subredes asignan IP pública.
#trivy:ignore:AWS-0164
resource "aws_subnet" "publica" {
  count = length(var.zonas)

  vpc_id                  = aws_vpc.principal.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = var.zonas[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.nombre}-subred-publica-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "principal" {
  vpc_id = aws_vpc.principal.id

  tags = {
    Name = "${var.nombre}-igw"
  }
}

resource "aws_route_table" "publica" {
  vpc_id = aws_vpc.principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.principal.id
  }

  tags = {
    Name = "${var.nombre}-rt-publica"
  }
}

resource "aws_route_table_association" "publica" {
  count = length(var.zonas)

  subnet_id      = aws_subnet.publica[count.index].id
  route_table_id = aws_route_table.publica.id
}
