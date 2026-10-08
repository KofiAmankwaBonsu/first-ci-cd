terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Same bucket as bootstrap/infra/org, distinct key. Manual-apply-only
  # layer, like bootstrap/ and org/ — this governs real human access across
  # accounts, a much bigger blast radius than anything the CI pipeline
  # should ever touch.
  backend "s3" {
    bucket       = "first-ci-cd-tfstate-537124953623"
    key          = "identity-center/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
