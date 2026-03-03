resource "random_string" "database_user" {
  length  = 12
  upper   = false
  numeric = false
  special = false
}

resource "random_password" "database_password" {
  length           = 16
  special          = true
  override_special = "!#$%&-_+"
}
