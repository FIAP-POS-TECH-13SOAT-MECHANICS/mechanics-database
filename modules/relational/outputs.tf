output "environment" {
  value = data.terraform_remote_state.shared.outputs.environment
}

output "service_name" {
  value = var.service_name
}

output "db_connection_string" {
  value = local.public ? "Server=${aws_db_instance.database.address},${aws_db_instance.database.port};Database=${var.service_name};User Id=${random_string.database_user.result};Password=${random_password.database_password.result};TrustServerCertificate=True;" : null

  sensitive = true
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db_credentials.name
}
