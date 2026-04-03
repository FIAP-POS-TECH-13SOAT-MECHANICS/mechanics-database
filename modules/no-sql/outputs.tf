output "environment" {
  value = data.terraform_remote_state.shared.outputs.environment
}

output "service_name" {
  value = var.service_name
}

output "db_table_name" {
  value = aws_dynamodb_table.database.name
}
