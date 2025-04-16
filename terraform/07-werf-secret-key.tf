resource "vault_mount" "werf-secret" {
  path        = "werf-secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "werf_secret" {
  mount                      = vault_mount.werf-secret.path
  name                       = "project-group/project-4/werf"
  delete_all_versions        = true
  data_json                  = jsonencode(
    {
        WERF_SECRET_KEY      = "43d9e7dae581a1400bf85115fc6ed97e"
    }
  )
}


# Создадим политику для деплоя в k8s и чтения секретов werf с учетом project
resource "vault_policy" "werf_secret_by_project" {
  name = "werf-per-project-access"
  policy = <<EOT
path "werf-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
path "kubernetes/creds/deploy_role" {
  capabilities = ["update"]
}
EOT
}

# Role for reading werf-secret

resource "vault_jwt_auth_backend_role" "werf_secret_by_project" {
  backend         = vault_jwt_auth_backend.gitlab.path
  role_name       = "werf-secret-by-gitlab-project"
  token_policies  = [vault_policy.werf_secret_by_project.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = {"project_path": "project_path"}

  user_claim      = "project_path"
  role_type       = "jwt"
  token_ttl       = 300
}



# Role for reading secret by env and deploy to k8s (project-5 example)

resource "vault_jwt_auth_backend_role" "role_project_5_example" {
  backend         = vault_jwt_auth_backend.gitlab.path
  role_name       = "role-can-read-secret-and-deploy"
  token_policies  = [vault_policy.read_by_project_env.name,vault_policy.deploy_policy.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = {"project_path": "project_path", "environment": "environment"}

  user_claim      = "project_path"
  role_type       = "jwt"
  token_ttl       = 300
}
