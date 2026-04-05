resource "aws_dynamodb_table" "customer_registration" {
  name           = "${var.customer_dynamo_table_table}${var.env_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity_units
  write_capacity = var.write_capacity_units
  hash_key       = "Id"
  range_key      = "CreatedAt"

  attribute {
    name = "Id"
    type = "S" # STRING - Guid will be stored as string
  }

  attribute {
    name = "CreatedAt"
    type = "N" # NUMBER - Unix timestamp (epoch seconds)
  }

  ttl {
    attribute_name = var.table_ttl_attribute_name
    enabled        = true
  }

  tags = {
    Environment = var.env_name
    Name        = "${var.customer_dynamo_table_table}${var.env_name}"
  }
}

output "customer_table_name" {
  description = "Customer DynamoDB table name"
  value       = aws_dynamodb_table.customer_registration.name
}

output "customer_table_arn" {
  description = "Customer DynamoDB table ARN"
  value       = aws_dynamodb_table.customer_registration.arn
}
