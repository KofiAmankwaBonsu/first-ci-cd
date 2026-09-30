terraform {
  # 1.10+ required for native S3 state locking (use_lockfile) — no DynamoDB table.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Migrated from a local backend after the first apply — see README.md.
  # Own state key is distinct from Layer 1's so the two never collide.
  backend "s3" {
    bucket       = "first-ci-cd-tfstate-537124953623"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
