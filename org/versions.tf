terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Same bucket bootstrap/infra use, distinct key. Manual-apply-only layer,
  # like bootstrap/ — creating/moving/closing AWS accounts is a much bigger
  # blast radius than infra/ manages, and the CI apply role has no
  # organizations:* permissions at all. Never wire this into the pipeline.
  backend "s3" {
    bucket       = "first-ci-cd-tfstate-537124953623"
    key          = "org/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
