variable {
  name        = "env_name"
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable {
  name = "vpc_cidr"
  type = string
}

variable {
  name = "public_subnet_cidr"
  type = string
}

variable {
  name = "app_subnet_cidr"
  type = string
}

variable {
  name = "data_subnet_cidr"
  type = string
}
