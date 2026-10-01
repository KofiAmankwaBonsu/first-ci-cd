## Problem

Deploying infrastructure to AWS manually is time consuming and prone to human errors.

## Solution

Set up a CI/CD pipeline that deploys infrastructure to AWS using Terraform, authenticating
via OIDC (no long-lived AWS access keys stored anywhere), plus a Terraform-managed IAM
users/groups setup to validate the OIDC trust configuration end-to-end.

## Status (as of 2026-10-01)

**Built and validated end-to-end.** A PR touching `infra/` triggers `plan` with a comment on the
PR; merging to `main` triggers `apply`, gated behind a `production` GitHub Environment approval;
both jobs authenticate via OIDC with zero stored AWS credentials. Confirmed by tagging the 4 test
IAM users through the real PR → review → merge → approve → apply path and seeing the tags land in
AWS.

Concrete values, for reference:

- AWS account `537124953623`, region `us-east-1`
- Repo: `KofiAmankwaBonsu/first-ci-cd`
- State bucket: `first-ci-cd-tfstate-537124953623` (native S3 locking, no DynamoDB — see below)
- `gh-actions-plan` / `gh-actions-apply` IAM roles, created in `bootstrap/`

Test IAM users/groups (step 8) are being kept intentionally for now rather than torn down —
there's more to build on `infra/` next.

## Assumptions (confirm or override)

These weren't specified, so the plan below picks a default. Flag any of these that are wrong:

- **CI/CD platform:** GitHub Actions. (Trust policy, token claims, and workflow syntax below
  are all GitHub-specific — swap in the GitLab/CircleCI equivalent if that's the actual target.)
- **AWS account structure:** single account to start. Multi-account (dev/staging/prod) is a
  straightforward extension (one OIDC role per account, one backend key prefix per env) but
  adds setup work not included here.
- **Repo layout:** single repo containing both the bootstrap config and the "real" infra.
- **IAM users/groups purpose:** a throwaway test harness to prove the pipeline can create/manage
  IAM resources under least privilege — not meant to be a long-term identity solution. If humans
  need real AWS console access, that should be AWS IAM Identity Center (SSO), not IAM users —
  worth a separate conversation.

## The dependency cycle problem

Terraform for the pipeline needs a remote backend (S3 + DynamoDB) and an OIDC IAM role to exist
*before* the pipeline can run — but the pipeline is what's supposed to create them. You can't use
a role to create the role that lets you assume it.

The fix is to split the config into two layers that are never applied the same way:

- **Layer 0 — `bootstrap/`**: creates the state backend, the OIDC provider, and the CI roles.
  Applied manually, once (and rarely afterward), from a human's own AWS credentials. Its own
  state lives separately from everything else.
- **Layer 1 — everything else** (real infra + the test IAM users/groups): uses the S3 backend
  and OIDC roles Layer 0 created. Applied only through the pipeline, never manually.

This also closes a security hole, not just a Terraform ordering problem: the CI role must
**not** have permission to modify the OIDC provider or its own trust policy/permissions.
Otherwise a compromised pipeline could grant itself more access — a privilege-escalation
cycle on top of the dependency cycle. Layer 0 stays out of reach of the automated role by
being in a directory/state the pipeline's IAM policy has no permissions over.

## Step-by-step procedure

**1. Decide account, region, and repo.**
Pin down the AWS account ID, region, and the exact `org/repo` name — the OIDC trust policy
needs to be scoped to this repo specifically, not left open to `*`.

**2. Write `bootstrap/` Terraform, using a local backend.**
Using your own admin AWS credentials (temporary, e.g. `aws sso login` or a session), write and
apply (`terraform init && terraform apply`, backend = `local`) a config that creates:
   - S3 bucket for remote state (versioning on, default encryption, block public access, bucket
     policy restricting access to your account/roles — state can contain secrets)
   - State locking via native S3 conditional writes (`use_lockfile = true` in the backend block,
     Terraform ≥1.10) — no DynamoDB table needed
   - IAM OIDC identity provider for `token.actions.githubusercontent.com`
   - `gh-actions-plan` IAM role — trust policy scoped to `repo:<org>/<repo>:*` (any branch/PR),
     permissions = read-only / `terraform plan`-only (no create/update/delete)
   - `gh-actions-apply` IAM role — trust policy scoped to `repo:<org>/<repo>:ref:refs/heads/main`
     (or a GitHub Environment claim), permissions = the actual deploy policy, least-privilege to
     the services Layer 1 manages — explicitly excluding IAM permissions over the OIDC provider
     and these two roles themselves

**3. Migrate bootstrap's own state into the bucket it just created.**
`terraform init -migrate-state` pointing at the new S3 backend, with a distinct state key (e.g.
`bootstrap/terraform.tfstate`) so it's clearly separated from Layer 1 state. Future changes to
Layer 0 are still applied manually/locally — never wire it into the pipeline.

**4. Record the outputs.**
Bucket name, DynamoDB table name, and both role ARNs. Role ARNs aren't secret and can go in the
repo (e.g. `.github/workflows/*.yml` or a vars file); nothing here needs to be a GitHub Secret,
which is the point of OIDC.

**5. Scaffold Layer 1.**
A `infra/` (or similar) directory with `backend "s3"` pointing at the bucket/table from step 2,
using a distinct state key from bootstrap. Include the test IAM users/groups config here as a
first, low-risk resource to deploy through the pipeline.

**6. Write the GitHub Actions workflow.**
   - On pull request: assume `gh-actions-plan` via OIDC (`aws-actions/configure-aws-credentials`
     with `role-to-assume`, no access keys), run `terraform plan`, post the plan output on the PR.
   - On merge to `main`: assume `gh-actions-apply`, run `terraform apply`, gated by a required
     PR review and/or a GitHub Environment protection rule requiring manual approval.

**7. Prove it end-to-end.**
Open a PR that touches the Layer 1 IAM users/groups config. Confirm the plan job runs and
authenticates with zero stored AWS credentials. Merge, confirm apply runs and the IAM
users/groups actually appear in AWS. This is the real validation of the whole setup.

**8. Decide the fate of the test IAM users/groups.**
Once OIDC is proven, either delete them (`terraform destroy` on just that piece) or document
why they're staying — don't leave them around as an unexplained leftover.

## Lessons learned while building this

Three non-obvious things broke `sts:AssumeRoleWithWebIdentity` after the trust policy looked
correct on paper — worth knowing before touching OIDC trust policies again:

1. **A job with `environment: <name>` changes the OIDC `sub` claim.** Instead of the ref-based
   `repo:OWNER/REPO:ref:refs/heads/main`, GitHub issues `repo:OWNER/REPO:environment:<name>`. The
   `apply` role's trust condition has to match the environment claim, not the branch ref, because
   the apply job declares `environment: production`.
2. **Repos created after 2026-07-15 default to GitHub's immutable OIDC subject format**, which
   embeds numeric owner/repo IDs: `repo:OWNER@OWNER-ID/REPO@REPO-ID:...` instead of
   `repo:OWNER/REPO:...`. `first-ci-cd` was created after that cutoff, so both trust policies had
   to be rebuilt around the actual numeric IDs (fetched via `GET /repos/OWNER/REPO`).
3. **Native S3 locking needs `s3:DeleteObject`, not just `Get`/`Put`.** `use_lockfile` writes a
   `<key>.tflock` object and deletes it on unlock — the first successful apply left a stale lock
   behind because the role could create the lock but not clear it, blocking the next run until
   cleared by hand.

Also: each CI role's S3 access is scoped to the `infra/` key prefix specifically, not the whole
bucket — `bootstrap/terraform.tfstate` stays out of reach of both roles, closing the same kind of
privilege-escalation gap called out above for the OIDC provider and the roles themselves.

## Guardrails

- `terraform fmt -check` and `terraform validate` on every PR — **done**, in the `plan` job
- A security/lint scanner (tfsec or checkov) on every PR — **not yet added**
- `prevent_destroy` lifecycle rule on anything stateful — in place on the state bucket itself;
  revisit once `infra/` grows anything else stateful
- State bucket encrypted, versioned, and not publicly accessible — **done**

## Success criteria — all met

- No long-lived AWS access keys exist anywhere (not in GitHub Secrets, not on a laptop) once
  bootstrap is complete.
- A PR touching Terraform triggers an automatic `plan` with visible output.
- A merge to `main` triggers an `apply` that requires human approval.
- The pipeline's IAM role cannot modify its own trust policy or the OIDC provider.
- Bootstrap resources (backend, OIDC provider, CI roles) are themselves Terraform-managed, just
  not pipeline-applied.

## Out of scope (for now)

- Multi-account/multi-environment setup
- Real human AWS access (Identity Center / SSO)
- Cost estimation (Infracost) and drift detection — worth adding once the pipeline is stable
