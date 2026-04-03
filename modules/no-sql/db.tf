locals {
  gsi_attributes = distinct(flatten([
    for gsi in var.global_secondary_indexes : [
      for ks in gsi.key_schema : {
        name = ks.attribute_name
        type = ks.attribute_type
      }
    ]
  ]))
}

resource "aws_dynamodb_table" "database" {
  name         = "${local.prefix}-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  dynamic "attribute" {
    for_each = local.gsi_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      projection_type = global_secondary_index.value.projection_type

      dynamic "key_schema" {
        for_each = global_secondary_index.value.key_schema
        content {
          attribute_name = key_schema.value.attribute_name
          key_type       = key_schema.value.key_type
        }
      }
    }
  }

  ttl {
    attribute_name = "expireAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = !local.public
  }

  server_side_encryption {
    enabled = true
  }
}
