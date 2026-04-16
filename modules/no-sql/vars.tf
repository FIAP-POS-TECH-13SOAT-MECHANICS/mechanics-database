variable "environment" {
  type = string
}

variable "service_name" {
  type = string
}

variable "table_name" {
  type    = string
  default = null
}

variable "global_secondary_indexes" {
  description = "GSIs for the DynamoDB table"
  type = list(object({
    name            = string
    projection_type = optional(string, "ALL")
    key_schema = list(object({
      attribute_name = string
      key_type       = string
      attribute_type = optional(string, "S")
    }))
  }))
  default = []
}
