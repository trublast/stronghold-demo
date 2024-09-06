# resource "vault_mount" "database" {
#   path = "database"
#   type = "database"
# }

# resource "vault_database_secret_backend_connection" "postgres" {
#   backend       = vault_mount.database.path
#   name          = "myapp-postgres"
#   allowed_roles = ["myapp","myapp-superuser"]

#   postgresql {
#     connection_url = "postgres://postgres:pgpass@postgres.myapp-namespace.svc:5432/postgres"
#   }
# }

# resource "vault_database_secret_backend_role" "role-myapp" {
#   backend             = vault_mount.database.path
#   name                = "myapp"
#   db_name             = vault_database_secret_backend_connection.postgres.name
#   default_ttl         = 3600
#   creation_statements = ["CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"]
# }

# resource "vault_database_secret_backend_role" "role-superuser" {
#   backend             = vault_mount.database.path
#   name                = "myapp-superuser"
#   db_name             = vault_database_secret_backend_connection.postgres.name
#   default_ttl         = 3600
#   creation_statements = ["CREATE ROLE \"{{name}}\" WITH SUPERUSER LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';"]
# }

# resource "vault_policy" "postgres-user" {
#   name = "postgres-user"
#   policy = file("policies/postgres-user.hcl")
# }

# resource "vault_identity_group" "postgres" {
#   name     = "postgres"
#   type     = "external"
#   policies = ["postgres-user"]

# }

# resource "vault_identity_group_alias" "group-alias" {
#   name           = "postgres"
#   mount_accessor = var.oidc_deckhouse_id
#   canonical_id   = vault_identity_group.postgres.id
# }

# # stronghold read database/creds/myapp
# # stronghold read database/creds/myapp-superuser

# # stronghold lease revoke -prefix=true -force=true database/creds/myapp
