variable "environment" {
  type    = string
}

variable "service_name" {
  type = string
}

variable "db_engine_version" {
  type    = string
  default = "15.00"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.small"
}
