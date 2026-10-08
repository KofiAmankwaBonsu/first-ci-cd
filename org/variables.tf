variable "aws_region" {
  description = "AWS region for the provider"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Management account ID — org-level resources must be managed from here"
  type        = string
  default     = "537124953623"
}
