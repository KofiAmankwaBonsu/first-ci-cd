output "organization_id" {
  value = aws_organizations_organization.this.id
}

output "root_id" {
  value = aws_organizations_organization.this.roots[0].id
}

output "prod_ou_id" {
  value = aws_organizations_organizational_unit.prod.id
}

output "dev_ou_id" {
  value = aws_organizations_organizational_unit.dev.id
}

output "prod_account_id" {
  value = aws_organizations_account.prod.id
}

output "dev_account_id" {
  value = aws_organizations_account.dev.id
}
