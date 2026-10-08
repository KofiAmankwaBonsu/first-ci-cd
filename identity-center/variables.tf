variable "aws_region" {
  description = "AWS region — must match the Identity Center instance's primary region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Management account ID — Identity Center admin calls must come from here (no delegated administrator is set)"
  type        = string
  default     = "537124953623"
}

variable "prod_account_id" {
  description = "Prod member account ID (org/accounts.tf)"
  type        = string
  default     = "435957166323"
}

variable "dev_account_id" {
  description = "Dev member account ID (org/accounts.tf)"
  type        = string
  default     = "639342569604"
}
