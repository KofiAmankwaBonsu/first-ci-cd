output "state_bucket_name" {
  value = aws_s3_bucket.tfstate.bucket
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "gh_actions_plan_role_arn" {
  value = aws_iam_role.gh_actions_plan.arn
}

output "gh_actions_apply_role_arn" {
  value = aws_iam_role.gh_actions_apply.arn
}
