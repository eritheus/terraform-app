############
# DynamoDB #
############

output "customer_table_name" {
  description = "Customer DynamoDB table name"
  value       = module.dynamo_customer_registration.name
}

output "customer_table_arn" {
  description = "Customer DynamoDB table ARN"
  value       = module.dynamo_customer_registration.arn
}