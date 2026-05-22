resource "vault_ldap_auth_backend" "ldap" {
  path = "ldap"
  url = "ldap://openldap.default.svc"
  binddn="cn=admin,dc=example,dc=com"
  bindpass="Password-1"
  userdn = "ou=Users,dc=example,dc=com"
  groupdn = "ou=Groups,dc=example,dc=com"
  username_as_alias = true
}

resource "vault_ldap_auth_backend_user" "ldap_user" {
  backend   = "ldap"
  username  = "alice"
  policies  = ["default", "admin"]

  groups = [
    "group1",
    "group2"
  ]

  # Здесь можно указать дополнительные опции, если необходимо
}
resource "vault_ldap_secret_backend" "ldap" {
  path = "ldap"
  url = "ldap://openldap.default.svc"
  binddn="cn=admin,dc=example,dc=com"
  bindpass="Password-1"
  userdn = "ou=Users,dc=example,dc=com"
}

# resource "vault_ldap_secret_backend_static_role" "alice" {
#   mount           = vault_ldap_secret_backend.ldap.path
#   username        = "alice"
#   dn              = "uid=alice,ou=users,dc=example,dc=com"
#   role_name       = "alice"
#   rotation_period = 3600 // In seconds (1 hour)
# }

# resource "vault_ldap_secret_backend_dynamic_role" "example_role" {
#   mount         = vault_ldap_secret_backend.ldap.path
#   role_name     = "project-user"
#   creation_ldif = <<EOT
# dn: cn={{.Username}},ou=Users,dc=example,dc=com
# changetype: add
# objectClass: inetOrgPerson
# cn: {{.Username}}
# sn: {{.Username}}
# userPassword: {{.Password}}
# EOT
#   deletion_ldif = <<EOT
# dn: cn={{.Username}},ou=Users,dc=example,dc=com
# changetype: delete
# EOT
# }
