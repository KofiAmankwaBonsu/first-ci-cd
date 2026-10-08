output "instance_arn" {
  value = local.instance_arn
}

output "identity_store_id" {
  value = local.identity_store_id
}

output "security_team_group_id" {
  value = aws_identitystore_group.security_team.group_id
}

output "developers_group_id" {
  value = aws_identitystore_group.developers.group_id
}
