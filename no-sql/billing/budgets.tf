module "budgets" {
  source = "../../modules/no-sql"

  environment  = var.environment
  service_name = "billing"
  table_name   = "budgets"

  global_secondary_indexes = [
    {
      name = "workOrderId-index"
      key_schema = [
        { attribute_name = "workOrderId", key_type = "HASH" },
      ]
    },
    {
      name = "customerId-index"
      key_schema = [
        { attribute_name = "customerId", key_type = "HASH" },
      ]
    }
  ]
}
