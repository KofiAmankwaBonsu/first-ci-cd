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
