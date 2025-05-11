# resource "vault_jwt_auth_backend" "gitlab" {
#     description = "Demo for gitlab"
#     path = "gitlab"
#     type = "jwt"
#     oidc_discovery_url  = "https://gitlab.demo-cluster.ru"
#     bound_issuer        = "https://gitlab.demo-cluster.ru"
# }

# # Создадим политику для секретов с учетом project
# resource "vault_policy" "read_by_project" {
#   name = "per-project-access"
#   policy = <<EOT
# path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
#   capabilities = ["read"]
# }
# EOT
# }

# # Создадим политику для секретов с учетом project + env
# resource "vault_policy" "read_by_project_env" {
#   name = "per-project-access-with-env"
#   policy = <<EOT
# path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.environment}}/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
#   capabilities = ["read"]
# }
# EOT
# }

# # Role for projects

# resource "vault_jwt_auth_backend_role" "role_by_project" {
#   backend         = vault_jwt_auth_backend.gitlab.path
#   role_name       = "read-by-gitlab-project"
#   token_policies  = [vault_policy.read_by_project.name]

#   bound_audiences = ["gitlab-access-aud"]
#   claim_mappings  = {"project_path": "project_path"}

#   user_claim      = "project_path"
#   role_type       = "jwt"
#   token_ttl       = 300
# }

# # Role for project + env

# resource "vault_jwt_auth_backend_role" "role_by_project_env" {
#   backend         = vault_jwt_auth_backend.gitlab.path
#   role_name       = "read-by-gitlab-project-env"
#   token_policies  =[vault_policy.read_by_project_env.name]

#   bound_audiences = ["gitlab-access-aud"]
#   claim_mappings  = {"project_path": "project_path", "environment": "environment"}

#   user_claim      = "project_path"
#   role_type       = "jwt"
#   token_ttl       = 300
# }


# # Создадим secret engine
# resource "vault_mount" "gitlab-secret" {
#   path        = "gitlab-secret"
#   type        = "kv"
#   options     = { version = "2" }
#   description = "Secrets for gitlab"
# }


# # секрет для проекта project-1
# resource "vault_kv_secret_v2" "gitlab-secret-project-1" {
#   mount                      = vault_mount.gitlab-secret.path
#   name                       = "project-group/project-1/mysecret"
#   data_json                  = jsonencode(
#     {
#         password       = "secret-password-for-project-1"
#     }
#   )
# }

# # секрет для проекта project-2
# resource "vault_kv_secret_v2" "gitlab-secret-project-2" {
#   mount                      = vault_mount.gitlab-secret.path
#   name                       = "project-group/project-2/mysecret"
#   data_json                  = jsonencode(
#     {
#         password       = "secret-password-for-project-2"
#     }
#   )
# }


# # секрет для проекта project-1
# resource "vault_kv_secret_v2" "gitlab-secret-project-1-production" {
#   mount                      = vault_mount.gitlab-secret.path
#   name                       = "production/project-group/project-1/mysecret"
#   data_json                  = jsonencode(
#     {
#         password       = "secret-password-for-project-1-production"
#     }
#   )
# }


# # секрет для проекта project-5
# resource "vault_kv_secret_v2" "gitlab-secret-project-5-production" {
#   mount                      = vault_mount.gitlab-secret.path
#   name                       = "production/project-group/project-5/mysecret"
#   data_json                  = jsonencode(
#     {
#         LOGIN          = "prod-my-secret-user"
#         PASSWORD       = "prod-secret-password-for-project-5"
#         DATABASE       = "prod-my-secret-database"
#     }
#   )
# }
# resource "vault_kv_secret_v2" "gitlab-secret-project-5-dev" {
#   mount                      = vault_mount.gitlab-secret.path
#   name                       = "dev/project-group/project-5/mysecret"
#   data_json                  = jsonencode(
#     {
#         LOGIN          = "dev-my-secret-user"
#         PASSWORD       = "dev-secret-password-for-project-5"
#         DATABASE       = "prod-my-secret-database"
#     }
#   )
# }
