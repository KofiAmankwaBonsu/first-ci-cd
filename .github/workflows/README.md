# One-time GitHub repo setup

Two things this workflow needs that can't be set from the YAML file itself.

## 1. Repository variables (role ARNs)

Not secrets — role ARNs aren't sensitive — but they live as repo variables
so the workflow doesn't need editing if the roles are ever recreated.

Via the UI: **Settings → Secrets and variables → Actions → Variables** →
add:

| Name | Value |
|---|---|
| `GH_ACTIONS_PLAN_ROLE_ARN` | `arn:aws:iam::537124953623:role/gh-actions-plan` |
| `GH_ACTIONS_APPLY_ROLE_ARN` | `arn:aws:iam::537124953623:role/gh-actions-apply` |

Or via `gh` CLI:

```
gh variable set GH_ACTIONS_PLAN_ROLE_ARN --body "arn:aws:iam::537124953623:role/gh-actions-plan"
gh variable set GH_ACTIONS_APPLY_ROLE_ARN --body "arn:aws:iam::537124953623:role/gh-actions-apply"
```

## 2. The `production` Environment (manual approval gate)

The `apply` job targets `environment: production`. Without an Environment
by that name configured with a required reviewer, GitHub just runs it
immediately on every merge to `main` — no approval gate at all.

**Settings → Environments → New environment** → name it `production` →
under **Deployment protection rules**, enable **Required reviewers** and
add yourself (or whoever should approve applies).

Skipping this doesn't break the workflow — it just silently removes the
approval step, which defeats the point of gating `apply` behind a human.
