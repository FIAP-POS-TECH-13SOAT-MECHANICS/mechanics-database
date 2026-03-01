# use "random_string" ao invés de "random_password" para facilitar outputs (ambiente público)

resource "random_string" "database_user" {
  length  = 12
  upper   = false
  numeric = false
  special = false
}

resource "random_string" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&-_+"
}