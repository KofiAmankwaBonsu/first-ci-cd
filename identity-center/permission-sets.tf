# One permission set per distinct level of access needed. developers gets
# two (full in Dev, read-only in Prod) because a permission set is a fixed
# bundle of policies — the split between accounts happens at the account
# assignment level, not by varying one permission set's contents.

resource "aws_ssoadmin_permission_set" "security_audit" {
  name             = "SecurityAudit"
  instance_arn     = local.instance_arn
  description      = "Read-only security/audit access"
  session_duration = "PT1H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_ssoadmin_permission_set" "developer_full_access" {
  name             = "DeveloperFullAccess"
  instance_arn     = local.instance_arn
  description      = "Full (non-IAM-admin) access for developers in Dev"
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_full_access" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_full_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_ssoadmin_permission_set" "developer_read_only" {
  name             = "DeveloperReadOnly"
  instance_arn     = local.instance_arn
  description      = "Read-only access for developers in Prod"
  session_duration = "PT1H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_read_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
