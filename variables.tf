variable "env_name" {
  description = "environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr"
  type = string
}

variable "app_subnet_cidr" {
  description = "app subnet cidr"
  type = string
}

variable "data_subnet_cidr" {
  description = "data subnet cidr"
  type = string
}
