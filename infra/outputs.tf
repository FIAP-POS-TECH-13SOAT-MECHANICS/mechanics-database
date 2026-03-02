output "environment" {
  value = local.environment_name
}

output "db_connection_string" {
  value = local.public ? "Server=${aws_db_instance.database.address},${aws_db_instance.database.port};Database=fiap-mechanics;User Id=${random_string.database_user.result};Password=${random_string.database_password.result};TrustServerCertificate=True;" : null
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "vpc_id" {
  value = aws_vpc.main.id
}