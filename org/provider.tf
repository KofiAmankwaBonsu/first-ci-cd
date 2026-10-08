provider "aws" {
  region = var.aws_region

  # Organizations API calls only succeed from the management account —
  # fail loudly rather than silently no-op against the wrong account.
  allowed_account_ids = [var.aws_account_id]
}
