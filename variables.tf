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
  default     = "customer-registration"
  type        = string
}

variable "table_ttl_attribute_name" {
  description = "DynamoDB TTL attribute name"
  type        = string
  default     = "ExpiresAt"
}

variable "domain_name" {
  description = "Domain name already owned outside AWS, used for the Route53 hosted zone and ACM certificate"
  type        = string
}

variable "allowed_cidrs" {
  description = "Team IP/CIDR allowlist for inbound access to the ALB (Fase 0 - no WAF yet, access control is this SG)"
  type        = list(string)
}
