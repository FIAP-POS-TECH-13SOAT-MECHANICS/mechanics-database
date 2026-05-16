module "payments" {
  source = "../../modules/no-sql"

  environment  = var.environment
  service_name = "billing"
  table_name   = "payments"

  global_secondary_indexes = [
    {
      name = "workOrderId-index"
      key_schema = [
        { attribute_name = "workOrderId", key_type = "HASH" },
      ]
    },
    {
      name = "budgetId-index"
      key_schema = [
        { attribute_name = "budgetId", key_type = "HASH" },
      ]
    },
    {
      name = "externalReference-index"
      key_schema = [
        { attribute_name = "externalReference", key_type = "HASH" },
      ]
    },
    {
      name = "mercadoPagoPaymentId-index"
      key_schema = [
        { attribute_name = "mercadoPagoPaymentId", key_type = "HASH" },
      ]
    }
  ]
}
