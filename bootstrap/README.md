# bootstrap

Creates the pieces the pipeline can't create for itself: the S3 state bucket,
the GitHub OIDC provider, and the two CI roles (`gh-actions-plan`,
`gh-actions-apply`). Applied manually, from your own AWS credentials, once
(and rarely afterward). Never wire this directory into the pipeline — see
`../project-scope.md` for why.

## First-time apply (local state)

```
cd bootstrap
terraform init
terraform plan
terraform apply
```

Uses your local AWS credentials (`aws sso login` / whatever profile is
active). State stays local for this first run because the S3 backend doesn't
exist yet.

## Migrate this config's own state into the S3 backend it just created

Once the apply above succeeds, point this config at the bucket it made,
under its own state key so it's clearly separated from Layer 1's state:

Edit `versions.tf` and replace `backend "local" {}` with:

```hcl
backend "s3" {
  bucket       = "first-ci-cd-tfstate-537124953623"
  key          = "bootstrap/terraform.tfstate"
  region       = "us-east-1"
  use_lockfile = true
  encrypt      = true
}
```

(Backend blocks can't reference variables — these are the literal values
from `terraform.tfvars`.)

Then:

```
terraform init -migrate-state
```

Confirm when prompted. From here on, any future bootstrap change is still
`terraform apply`'d manually — just against remote state instead of local.

## After this

Note the four outputs (`terraform output`) — Layer 1's backend config and the
GitHub Actions workflow both need them:

- `state_bucket_name` — Layer 1's S3 backend bucket
- `gh_actions_plan_role_arn` — `role-to-assume` for the PR/plan job
- `gh_actions_apply_role_arn` — `role-to-assume` for the main/apply job

None of these are secrets — role ARNs and a bucket name can live directly in
the workflow YAML or repo vars, no GitHub Secrets needed.
