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

########
# DNS  #
########

output "hosted_zone_id" {
  description = "Route53 hosted zone ID for the apex domain (looked up, not managed here)"
  value       = data.aws_route53_zone.primary.zone_id
}

output "dev_zone_id" {
  description = "Route53 hosted zone ID for the dev.<domain> subzone (dev workspace only)"
  value       = local.is_prod ? null : aws_route53_zone.dev[0].zone_id
}

########
# ACM  #
########

output "acm_certificate_arn" {
  description = "Validated ACM certificate ARN for the app domain in this workspace (us-east-2, used by the ALB listener)"
  value       = aws_acm_certificate_validation.app.certificate_arn
}

########
# ALB  #
########

output "app_url" {
  description = "Public HTTPS URL for the customer-registration-app in this workspace"
  value       = "https://${local.app_domain}"
}
