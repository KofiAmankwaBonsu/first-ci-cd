provider "aws" {
  region = var.aws_region

  allowed_account_ids = [var.aws_account_id]
}

data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = data.aws_ssoadmin_instances.this.arns[0]
  identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]
}
