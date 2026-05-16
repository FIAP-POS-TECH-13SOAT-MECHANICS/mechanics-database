module "database" {
  source = "../../modules/relational"

  environment  = var.environment
  service_name = "identity"
}
