output "environment" {
  value = module.database.environment
}

output "service_name" {
  value = module.database.service_name
}

output "database_name" {
  value = module.database.database_name
}

output "db_connection_string" {
  value     = module.database.db_connection_string
  sensitive = true
}

output "db_secret_name" {
  value = module.database.db_secret_name
}
