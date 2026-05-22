resource "vault_policy" "demo-admin" {
  name = "demo-admin"
  policy = file("policies/admin.hcl")
}

resource "vault_policy" "demo-user" {
  name = "demo-user"
  policy = file("policies/readonly.hcl")
}

resource "vault_auth_backend" "userpass" {
    type        = "userpass"
}

resource "vault_generic_endpoint" "demo-admin" {
  depends_on = [ vault_auth_backend.userpass ]
  path                 = "auth/userpass/users/demo-admin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["demo-admin"],
  "password": "Password-1"
}
EOT
}

resource "vault_generic_endpoint" "demo-user" {
  depends_on = [ vault_auth_backend.userpass ]
  path                 = "auth/userpass/users/demo-user"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["demo-user"],
  "password": "Password-1"
}
EOT
}
