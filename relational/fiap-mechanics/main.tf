module "database" {
  source = "../../modules/relational"

  environment  = var.environment
  service_name = "fiap-mechanics"
  database_name = "fiap-mechanics"
}
