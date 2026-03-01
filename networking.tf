resource "aws_vpc" "app_vpc" {
  cidr_block = var.vpc_cidr
  region     = "us-east-2"

  tags = {
    Name = "vpc-${var.env_name}"
  }
}

resource "aws_subnet" "public_subnet" {
  cidr_block = var.public_subnet_cidr
  region     = "us-east-2"
  vpc_id     = aws_vpc.app_vpc.id

  tags = {
    Name = "public-subnet-${var.env_name}"
  }
}

resource "aws_subnet" "app_subnet" {
  cidr_block = var.app_subnet_cidr
  region     = "us-east-2"
  vpc_id     = aws_vpc.app_vpc.id

  tags = {
    Name = "app-subnet-${var.env_name}"
  }
}

resource "aws_subnet" "data_subnet" {
  cidr_block = var.data_subnet_cidr
  region     = "us-east-2"
  vpc_id     = aws_vpc.app_vpc.id

  tags = {
    Name = "data-subnet-${var.env_name}"
  }
}
