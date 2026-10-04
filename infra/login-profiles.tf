# Console passwords, forced reset on first login — this is the part that
# actually simulates a human signing in, as opposed to a bare identity.
#
# Known limitation: Terraform generates and stores the password in state
# (redacted from plan/apply output, but present in the raw state object).
# Both CI roles can read state under infra/* (bootstrap/iam-roles.tf), so
# this is fine for a demo but is exactly the kind of thing real human
# access should go through AWS IAM Identity Center for instead, not
# Terraform-managed IAM users — see project-scope.md.

resource "aws_iam_user_login_profile" "security_team" {
  for_each = aws_iam_user.security_team

  user                    = each.value.name
  password_reset_required = true
}

resource "aws_iam_user_login_profile" "developers" {
  for_each = aws_iam_user.developers

  user                    = each.value.name
  password_reset_required = true
}
