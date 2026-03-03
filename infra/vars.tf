variable "environment" {
  type    = string
  default = "dev"
}

variable "db_engine_version" {
  type    = string
  default = "15.00"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
}
