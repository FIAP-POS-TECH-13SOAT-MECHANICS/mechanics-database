# remote states

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "fiap-mechanics-tf-${data.aws_caller_identity.current.account_id}"
    key    = "shared-${var.environment}.tfstate"
    region = "us-east-1"
  }
}

# locals

locals {
  prefix = "${var.service_name}-${var.environment}"
  public = data.terraform_remote_state.shared.outputs.public_access
}
