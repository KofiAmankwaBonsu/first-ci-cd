resource "aws_organizations_account" "prod" {
  name      = "Prod"
  email     = "amankwaabonsu+prod@yahoo.com"
  parent_id = aws_organizations_organizational_unit.prod.id

  # role_name and iam_user_access_to_billing are only set at account
  # creation time — AWS never returns them on subsequent reads, so
  # Terraform can't refresh them. Without this, every plan would show a
  # spurious diff trying to "fix" values it can't actually see.
  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_account" "dev" {
  name      = "Dev"
  email     = "amankwaabonsu+dev@yahoo.com"
  parent_id = aws_organizations_organizational_unit.dev.id

  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}
