locals {
  az_suffixes = [for az in var.availability_zones : substr(az, -1, 1)]
}

resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr
  region     = "us-east-2"

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
