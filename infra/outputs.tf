output "security_team_group_name" {
  value = aws_iam_group.security_team.name
}

output "security_team_usernames" {
  value = [for u in aws_iam_user.security_team : u.name]
}

output "developers_group_name" {
  value = aws_iam_group.developers.name
}

output "developer_usernames" {
  value = [for u in aws_iam_user.developers : u.name]
}
