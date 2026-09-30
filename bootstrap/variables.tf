variable "aws_region" {
  description = "AWS region for all bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID the bootstrap resources are created in"
  type        = string
}

variable "github_repo" {
  description = "GitHub org/repo allowed to assume the CI roles, e.g. KofiAmankwaBonsu/first-ci-cd"
  type        = string
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state"
  type        = string
}
