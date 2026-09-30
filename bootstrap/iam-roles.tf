locals {
  github_repo_owner = split("/", var.github_repo)[0]
  github_repo_name  = split("/", var.github_repo)[1]

  # Repos created after 2026-07-15 default to GitHub's immutable OIDC
  # subject format, which embeds numeric owner/repo IDs instead of just
  # names: "repo:OWNER@OWNER-ID/REPO@REPO-ID:...". first-ci-cd was created
  # after that cutoff, so both conditions below must use this form or
  # AssumeRoleWithWebIdentity is denied regardless of everything else being
  # correct. IDs came from `GET /repos/OWNER/REPO` (repo id, owner.id).
  github_oidc_subject_prefix = "repo:${local.github_repo_owner}@${var.github_owner_id}/${local.github_repo_name}@${var.github_repo_id}"

  # Plan role: assumable from any branch/PR in the repo (PRs need plan too).
  github_oidc_sub_any_ref = "${local.github_oidc_subject_prefix}:*"
  # Apply role: the apply job declares `environment: production`, which
  # makes GitHub swap the token's sub claim from the ref-based form to
  # "...:environment:NAME" instead — so the trust condition has to match on
  # the environment, not on refs/heads/main.
  github_oidc_sub_production_env = "${local.github_oidc_subject_prefix}:environment:production"
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
  # Scoped to the infra/ key prefix only — these are the CI roles, and
  # bootstrap/terraform.tfstate must stay out of their reach the same way
  # the OIDC provider and the roles themselves do. Bootstrap is applied
  # manually with separate (admin) credentials, never through these roles.
  statement {
    sid    = "InfraStateObjectReadWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.tfstate.arn}/infra/*",
    ]
  }

  statement {
    sid       = "ListInfraStatePrefixOnly"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["infra/*"]
    }
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
      values   = [local.github_oidc_sub_production_env]
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
