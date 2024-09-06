resource "vault_mount" "secret" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

# resource "vault_kv_secret_v2" "myapp_secret" {
#   mount                      = vault_mount.secret.path
#   name                       = "myapp"
#   cas                        = 1
#   delete_all_versions        = true
#   data_json                  = jsonencode(
#     {
#         password       = "secret-password"
#     }
#   )
# }

# stronghold login -method=oidc -path=oidc_deckhouse -no-print
# stronghold kv put secret/myapp password="secret-password"

resource "vault_policy" "myapp" {
  name = "myapp"
  policy = file("policies/myapp.hcl")
}

resource "vault_kubernetes_auth_backend_role" "myapp" {
  backend                          ="kubernetes_local"
  role_name                        = vault_policy.myapp.name
  bound_service_account_names      = ["myapp"]
  bound_service_account_namespaces = ["myapp-namespace"]
  token_ttl                        = 60
  token_policies                   = ["myapp"]
}
