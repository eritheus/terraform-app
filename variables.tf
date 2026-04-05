variable "env_name" {
  description = "environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
}

variable "public_subnet_cidr" {
  description = "public subnet cidr"
  type        = string
}

variable "app_subnet_cidr" {
  description = "app subnet cidr"
  type        = string
}

variable "data_subnet_cidr" {
  description = "data subnet cidr"
  type        = string
}

variable "customer_dynamo_table_table" {
  description = "Customer DynamoDB table name"
  default     = "customer-registration-"
  type        = string
}

variable "read_capacity_units" {
  description = "DynamoDB read capacity units"
  type        = number
  default     = 5
}

variable "write_capacity_units" {
  description = "DynamoDB write capacity units"
  type        = number
  default     = 5
}

variable "table_ttl_attribute_name" {
  description = "DynamoDB TTL attribute name"
  type        = string
  default     = "ExpiresAt"
}