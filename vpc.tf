data "aws_availability_zones" "available" {}

resource "aws_vpc" "poc_keycloak" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
}

resource "aws_subnet" "keycloak_public" {
  count                   = var.availability_zone_count
  cidr_block              = cidrsubnet(aws_vpc.poc_keycloak.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.poc_keycloak.id
  map_public_ip_on_launch = true

  tags = {
    Name = "keycloak Public Subnet"
  }
}

resource "aws_subnet" "keycloak_private" {
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = data.aws_availability_zones.available.names[1]
  vpc_id            = aws_vpc.poc_keycloak.id

  tags = {
    Name = "Keycloak Private Subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.poc_keycloak.id
}
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.keycloak_public[0].id
}
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.poc_keycloak.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "table routage public"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.availability_zone_count
  subnet_id      = element(aws_subnet.keycloak_public.*.id, count.index)
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.poc_keycloak.id

  tags = {
    Name = "table routage privé"
  }
}
resource "aws_route_table_association" "prive" {
  subnet_id      = aws_subnet.keycloak_private.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route" "nat_route" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat.id
}
resource "aws_security_group" "keycloak_sg" {
  description = "The security group used by the keycloak server"

  vpc_id = aws_vpc.poc_keycloak.id

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_security_group" "keycloak_bastion_sg" {
  description = "The security group used by the bastion instance"
  vpc_id      = aws_vpc.poc_keycloak.id
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "keycloak_admin_access" {
  description = "The security group allowing SSH administrative access to the instances"
  vpc_id      = aws_vpc.poc_keycloak.id

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [aws_security_group.keycloak_bastion_sg.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all from private subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.keycloak_private.cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
resource "aws_security_group" "elb" {
  name        = "sec_group_elb"
  description = "Security group for public facing ELBs"
  vpc_id      = aws_vpc.poc_keycloak.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}