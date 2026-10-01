variable "aws_region" {
  description = "AWS region for all infra resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID these resources are created in"
  type        = string
  default     = "537124953623"
}

variable "security_team_usernames" {
  description = "IAM usernames to create in the security-team group"
  type        = list(string)
  default     = ["security-team-1", "security-team-2"]
}

variable "developer_usernames" {
  description = "IAM usernames to create in the developers group"
  type        = list(string)
  default     = ["developer-1", "developer-2", "developer-3"]
}
