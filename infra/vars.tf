variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "fiap-mechanics"
}

variable "email_domain" {
  type = string
  default = "mechanics.com"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Name for the environment (dev, stg or prod)"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of 'dev', 'stg', or 'prod'."
  }
}

variable "environment_map" {
  type = map(string)
  default = {
    dev  = "Development"
    stg  = "Staging"
    prod = "Production"
  }
}

variable "public_access" {
  type        = bool
  nullable    = true
  default     = null
  description = "If internal services - like database and SMTP server - will be publicly accessible"
}

variable "availability_zones" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Availability Zones to be used in the VPC"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

locals {
  prefix           = "${var.project_name}-${var.environment}"
  environment_name = var.environment_map[var.environment]
  public           = var.public_access != null ? var.public_access : var.environment != "prod"
}
