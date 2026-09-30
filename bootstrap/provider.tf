provider "aws" {
  region = var.aws_region

  # Fail loudly if the local credentials point at the wrong account.
  allowed_account_ids = [var.aws_account_id]
}
