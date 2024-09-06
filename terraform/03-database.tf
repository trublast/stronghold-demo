resource "vault_kubernetes_auth_backend_role" "postgres" {
  backend                          ="kubernetes_local"
  role_name                        = vault_policy.postgres.name
  bound_service_account_names      = ["postgres"]
  bound_service_account_namespaces = ["myapp-namespace"]
  token_ttl                        = 60
  token_policies                   = ["postgres"]
}

resource "vault_policy" "postgres" {
  name = "postgres"
  policy = file("policies/postgres.hcl")
}
# stronghold kv put secret/postgres password="pgpass"
# kubectl exec postgres-0 -c postgres  -it -- psql -d postgres -h postgres -U postgres
