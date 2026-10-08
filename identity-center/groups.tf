# Built-in Identity Center directory for now — external IdP federation can
# replace this later without changing anything downstream (permission sets
# and account assignments reference the group ID, not how it was created).

resource "aws_identitystore_group" "security_team" {
  identity_store_id = local.identity_store_id
  display_name      = "security-team"
  description       = "Security team — audit access across all accounts"
}

resource "aws_identitystore_group" "developers" {
  identity_store_id = local.identity_store_id
  display_name      = "developers"
  description       = "Developers — full access in Dev, read-only in Prod"
}
