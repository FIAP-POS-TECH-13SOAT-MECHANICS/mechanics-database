resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.prefix}-database"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials_value" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    value = "Server=${aws_db_instance.database.address},${aws_db_instance.database.port};Database=${var.service_name};User Id=${random_string.database_user.result};Password=${random_password.database_password.result};"
  })
}
