module "dynamo_customer_registration" {
  source = "git::https://github.com/eritheus/terraform-modules.git//dynamodb-table?ref=main"
  name   = var.customer_dynamo_table_table

  hash_key           = "Id"
  range_key          = "CreatedAt"
  ttl_attribute_name = var.table_ttl_attribute_name

  attributes = [
    { name = "Id", type = "S" },        # STRING - Guid will be stored as string
    { name = "CreatedAt", type = "N" }, # NUMBER - Unix timestamp (epoch seconds)
  ]
}