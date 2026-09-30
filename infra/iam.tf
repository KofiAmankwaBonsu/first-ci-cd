# Test IAM users/groups — validates that the pipeline's apply role
# (scoped to exactly these actions in bootstrap/iam-roles.tf) can actually
# manage IAM resources end-to-end. No login profiles or access keys are
# created here on purpose: these are identities to prove the setup works,
# not accounts anyone signs in with.

resource "aws_iam_group" "security_team" {
  name = "security-team"
}

resource "aws_iam_group" "developers" {
  name = "developers"
}

resource "aws_iam_user" "security_team" {
  for_each = toset(var.security_team_usernames)
  name     = each.key
}

resource "aws_iam_user" "developers" {
  for_each = toset(var.developer_usernames)
  name     = each.key
}

resource "aws_iam_group_membership" "security_team" {
  name  = "security-team-membership"
  group = aws_iam_group.security_team.name
  users = [for u in aws_iam_user.security_team : u.name]
}

resource "aws_iam_group_membership" "developers" {
  name  = "developers-membership"
  group = aws_iam_group.developers.name
  users = [for u in aws_iam_user.developers : u.name]
}

# Illustrative only — swap for whatever each group should actually be able
# to do. SecurityAudit/ReadOnlyAccess are both read-only AWS managed
# policies, chosen here so this demo can't accidentally grant real access.
resource "aws_iam_group_policy_attachment" "security_team_audit" {
  group      = aws_iam_group.security_team.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_group_policy_attachment" "developers_readonly" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
