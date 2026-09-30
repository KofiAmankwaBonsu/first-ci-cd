terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Same bucket bootstrap created, distinct state key so the two configs
  # never collide. This config is applied only by the pipeline via the
  # gh-actions-plan/gh-actions-apply roles — never manually.
  backend "s3" {
    bucket       = "first-ci-cd-tfstate-537124953623"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
