module "budgets" {
  source = "../../modules/no-sql"

  environment  = var.environment
  service_name = "billing"
  table_name   = "budgets"

  global_secondary_indexes = [
    {
      name = "customerId-index"
      key_schema = [
        { attribute_name = "customerId", key_type = "HASH" },
        { attribute_name = "expirationDate", key_type = "RANGE" }
      ]
    },
    {
      name = "orderId-index"
      key_schema = [
        { attribute_name = "orderId", key_type = "HASH" },
        { attribute_name = "expirationDate", key_type = "RANGE" }
      ]
    }
  ]
}
