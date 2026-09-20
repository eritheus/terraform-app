locals {
  az_suffixes = [for az in var.availability_zones : substr(az, -1, 1)]
}

resource "aws_vpc" "app_vpc" {
  cidr_block           = var.vpc_cidr
  region               = "us-east-2"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  region            = "us-east-2"

  tags = {
    Name = "${var.env_name}-public-${local.az_suffixes[count.index]}"
  }
}

# Internet Gateway + route table publica para as subnets `public` (#34) -
# necessario para o ALB ser alcancavel da internet. As subnets `app`/`data`
# continuam sem rota de internet (privadas, alcancam AWS via VPC endpoints).
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "${var.env_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.env_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "app" {
  count             = length(var.app_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  region            = "us-east-2"

  tags = {
    Name = "${var.env_name}-app-${local.az_suffixes[count.index]}"
  }
}

resource "aws_subnet" "data" {
  count             = length(var.data_subnet_cidrs)
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  region            = "us-east-2"

  tags = {
    Name = "${var.env_name}-data-${local.az_suffixes[count.index]}"
  }
}

# VPC endpoints so Fargate tasks in private app subnets can reach CloudWatch
# Logs and ECR without a NAT Gateway. Interface endpoints (~$7/mo each) are
# cheaper than a NAT Gateway (~$32/mo per AZ) at this scale.
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.env_name}-vpc-endpoints-sg"
  description = "Allow HTTPS from app subnets to interface endpoints"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.app_subnet_cidrs
  }

  tags = {
    Name = "${var.env_name}-vpc-endpoints-sg"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["logs", "ecr.api", "ecr.dkr"])

  vpc_id              = aws_vpc.app_vpc.id
  service_name        = "com.amazonaws.us-east-2.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.app[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.env_name}-${each.value}-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.app_vpc.main_route_table_id]

  tags = {
    Name = "${var.env_name}-s3-endpoint"
  }
}

# Gateway endpoint (free, no hourly cost like the interface endpoints above)
# so tasks in the private `app` subnets can reach DynamoDB. Without this,
# calls to DynamoDB from the app subnets have no route out at all (no NAT,
# no IGW route there) and just hang until the caller's timeout - this was
# missing and caused GET / (which calls DynamoDB) to hang and 504 at the
# ALB, while /health (no DynamoDB call) kept responding fine.
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.app_vpc.id
  service_name      = "com.amazonaws.us-east-2.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.app_vpc.main_route_table_id]

  tags = {
    Name = "${var.env_name}-dynamodb-endpoint"
  }
}
