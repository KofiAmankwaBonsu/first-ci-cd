locals {
  # Plan role: assumable from any branch/PR in the repo (PRs need plan too).
  github_oidc_sub_any_ref = "repo:${var.github_repo}:*"
  # Apply role: assumable only when the workflow is running off main.
  github_oidc_sub_main_ref = "repo:${var.github_repo}:ref:refs/heads/main"
}

# ---------------------------------------------------------------------------
# Plan role — read-only, assumable from any branch/PR
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_sub_any_ref]
    }
  }
}

resource "aws_iam_role" "gh_actions_plan" {
  name               = "gh-actions-plan"
  assume_role_policy = data.aws_iam_policy_document.plan_trust.json
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.gh_actions_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------------------------------------------------------------------------
# Shared: read/write access to the state bucket (both roles need this)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "state_backend_access" {
  statement {
    sid    = "StateBucketReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "state_backend_access" {
  name   = "terraform-state-backend-access"
  policy = data.aws_iam_policy_document.state_backend_access.json
}

resource "aws_iam_role_policy_attachment" "plan_state_access" {
  role       = aws_iam_role.gh_actions_plan.name
  policy_arn = aws_iam_policy.state_backend_access.arn
}

# ---------------------------------------------------------------------------
# Apply role — deploy permissions, only from main
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_sub_main_ref]
    }
  }
}

resource "aws_iam_role" "gh_actions_apply" {
  name               = "gh-actions-apply"
  assume_role_policy = data.aws_iam_policy_document.apply_trust.json
}

resource "aws_iam_role_policy_attachment" "apply_state_access" {
  role       = aws_iam_role.gh_actions_apply.name
  policy_arn = aws_iam_policy.state_backend_access.arn
}

# Scoped to exactly what Layer 1 manages today: the test IAM users/groups.
# Expand this as real infra gets added — resist granting broad admin access
# "to save time later"; that defeats the point of least privilege.
data "aws_iam_policy_document" "apply_permissions" {
  statement {
    sid    = "ManageTestIamUsersAndGroups"
    effect = "Allow"
    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:GetUser",
      "iam:ListUsers",
      "iam:TagUser",
      "iam:UntagUser",
      "iam:CreateGroup",
      "iam:DeleteGroup",
      "iam:GetGroup",
      "iam:ListGroups",
      "iam:AddUserToGroup",
      "iam:RemoveUserFromGroup",
      "iam:AttachGroupPolicy",
      "iam:DetachGroupPolicy",
      "iam:ListAttachedGroupPolicies",
      "iam:ListGroupsForUser",
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:user/*",
      "arn:aws:iam::${var.aws_account_id}:group/*",
    ]
  }

  # Close the privilege-escalation loop: the apply role can manage IAM users
  # and groups, but must never touch the OIDC provider or either CI role —
  # otherwise a compromised pipeline run could grant itself more access.
  # Explicit Deny wins over every Allow above, including the managed policy.
  statement {
    sid    = "DenySelfModification"
    effect = "Deny"
    actions = [
      "iam:*",
    ]
    resources = [
      aws_iam_openid_connect_provider.github.arn,
      aws_iam_role.gh_actions_plan.arn,
      aws_iam_role.gh_actions_apply.arn,
    ]
  }
}

resource "aws_iam_policy" "apply_permissions" {
  name   = "gh-actions-apply-permissions"
  policy = data.aws_iam_policy_document.apply_permissions.json
}

resource "aws_iam_role_policy_attachment" "apply_permissions" {
  role       = aws_iam_role.gh_actions_apply.name
  policy_arn = aws_iam_policy.apply_permissions.arn
}
