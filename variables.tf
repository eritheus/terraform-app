variable "env_name" {
  description = "environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "vpc cidr"
  type        = string
}

variable "availability_zones" {
  description = "availability zones to spread subnets across (one per AZ)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "public subnet cidrs, one per AZ, same order as availability_zones"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "app subnet cidrs, one per AZ, same order as availability_zones"
  type        = list(string)
}

variable "data_subnet_cidrs" {
  description = "data subnet cidrs, one per AZ, same order as availability_zones"
  type        = list(string)
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
