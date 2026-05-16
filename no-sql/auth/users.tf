module "users" {
  source = "../../modules/no-sql"

  environment  = var.environment
  service_name = "auth"
  table_name   = "users"

  global_secondary_indexes = [
    {
      name = "cpfNumber-index"
      key_schema = [
        { attribute_name = "cpfNumber", key_type = "HASH" },
      ]
    }
  ]
}
