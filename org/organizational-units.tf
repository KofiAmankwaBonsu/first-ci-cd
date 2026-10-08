resource "aws_organizations_organizational_unit" "prod" {
  name      = "ProdOU"
  parent_id = aws_organizations_organization.this.roots[0].id
}

# Originally created as "SecurityOU", renamed to stand in as the Dev
# environment for now — see project-scope.md.
resource "aws_organizations_organizational_unit" "dev" {
  name      = "DevOU"
  parent_id = aws_organizations_organization.this.roots[0].id
}
