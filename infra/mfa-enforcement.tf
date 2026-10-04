# AWS's standard pattern: allow self-service MFA enrollment and password
# management, deny everything else unless the session is MFA-authenticated.
# This is what actually makes the console logins above behave like a real
# human-access setup instead of a password that just... works. The explicit
# Deny overrides the SecurityAudit/ReadOnlyAccess managed policies already
# attached to both groups, so neither group can use those permissions
# without MFA first.

data "aws_iam_policy_document" "require_mfa" {
  statement {
    sid    = "AllowViewAccountInfo"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "iam:ListVirtualMFADevices",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnPasswordAndMFA"
    effect = "Allow"
    actions = [
      "iam:ChangePassword",
      "iam:GetUser",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:user/$${aws:username}",
      "arn:aws:iam::${var.aws_account_id}:mfa/$${aws:username}",
    ]
  }

  statement {
    sid    = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"
    not_actions = [
      "iam:ChangePassword",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:GetUser",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary",
      "sts:GetSessionToken",
    ]
    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_group_policy" "security_team_require_mfa" {
  name   = "require-mfa"
  group  = aws_iam_group.security_team.name
  policy = data.aws_iam_policy_document.require_mfa.json
}

resource "aws_iam_group_policy" "developers_require_mfa" {
  name   = "require-mfa"
  group  = aws_iam_group.developers.name
  policy = data.aws_iam_policy_document.require_mfa.json
}
