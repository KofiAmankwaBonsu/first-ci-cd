# depends_on is explicit here because nothing else ties an assignment to
# its policy attachment — without it, Terraform could create the account
# assignment before the managed policy is actually attached, provisioning
# an empty permission set to the account.

resource "aws_ssoadmin_account_assignment" "security_team_prod" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security_team.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_account_id
  target_type        = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_managed_policy_attachment.security_audit]
}

resource "aws_ssoadmin_account_assignment" "security_team_dev" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security_team.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_account_id
  target_type        = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_managed_policy_attachment.security_audit]
}

resource "aws_ssoadmin_account_assignment" "developers_dev" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_full_access.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_account_id
  target_type        = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_managed_policy_attachment.developer_full_access]
}

resource "aws_ssoadmin_account_assignment" "developers_prod" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_read_only.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_account_id
  target_type        = "AWS_ACCOUNT"

  depends_on = [aws_ssoadmin_managed_policy_attachment.developer_read_only]
}
