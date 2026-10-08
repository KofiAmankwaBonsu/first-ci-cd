# org

Manages the AWS Organization itself: org-wide settings, OUs, and member
accounts. Applied manually from the management account's own admin
credentials — like `bootstrap/`, never wired into the CI pipeline. Creating,
moving, or closing AWS accounts is a much bigger blast radius than anything
`infra/` touches, and the `gh-actions-apply` role has no `organizations:*`
permissions at all.

Current structure:

- Management account `537124953623` — stays at root, runs the OIDC CI/CD
  pipeline (`bootstrap/`, `infra/`)
- `ProdOU` → `Prod` account (`435957166323`)
- `DevOU` (renamed from `SecurityOU`) → `Dev` account (`639342569604`),
  standing in for the dev environment for now

Everything here was created by hand first (`aws organizations create-account`
/ `move-account`), then imported:

```
terraform import aws_organizations_organization.this o-vwzu95x60h
terraform import aws_organizations_organizational_unit.prod ou-uuq2-ky11iahu
terraform import aws_organizations_organizational_unit.dev ou-uuq2-fh9czj4q
terraform import aws_organizations_account.prod 435957166323
terraform import aws_organizations_account.dev 639342569604
```

`terraform plan` right after import showed zero diff — the config in this
directory matches exactly what's live.

Known quirk: `aws_organizations_account.*` has `role_name` and
`iam_user_access_to_billing` under `lifecycle.ignore_changes` — AWS only
accepts those at account-creation time and never returns them on later
reads, so without ignoring them every plan would show a spurious diff
Terraform can't actually resolve.
