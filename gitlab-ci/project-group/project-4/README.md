## Что в этом примере

### job_kubernetes_deploy

1. Аутентифицируется в Stronghold используя роль `werf-secret-by-gitlab-project`
2. Получает JWT сервис-аккаунта Kubernetes на освновании роли `kubernetes/creds/deploy_role` для взаимодействия с API Kubernetes
3. Получает WERF_SECRET_KEY из `werf-secret/${CI_PROJECT_PATH}/werf` для расшифровки `.helm/secret-values.yaml`
3. Выполняет деплой helm-чарта

### job_kubernetes_uninstall

1. Аутентифицируется в Stronghold используя роль `werf-secret-by-gitlab-project`
2. Получает JWT сервис-аккаунта Kubernetes на освновании роли `kubernetes/creds/deploy_role` для взаимодействия с API Kubernetes
3. Выполняет деинсталляцию helm-чарта


## Политика доступа и claim

```
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
```
