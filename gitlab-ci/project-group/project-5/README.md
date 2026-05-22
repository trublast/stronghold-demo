# Секреты приложения в Kubernetes по окружению GitLab

Пайплайн читает KV по пути `gitlab-secret/${CI_ENVIRONMENT_SLUG}/${CI_PROJECT_PATH}/mysecret`, кодирует поля в `WERF_SET_SECRETS` и передаёт в Helm как `global.secrets`. Pod получает переменные через `envFrom` → Secret. Для `dev` и `production` — разные записи в Stronghold; ротация в CI не требуется.

## Что демонстрирует пример

- Одна JWT-роль `role-can-read-secret-and-deploy`: чтение KV по environment + project и выдача kube-токена.
- Два deploy-job с разными `environment:` — разные секреты в кластере.
- Загрузка произвольного набора ключей из KV через HTTP API и `jq` (альтернатива поштучному `kv get`).

## Jobs в `.gitlab-ci.yml`

| Job | GitLab Environment | Секрет в Stronghold |
|-----|-------------------|---------------------|
| `job_kubernetes_deploy_dev` | `dev` | `gitlab-secret/dev/project-group/project-5/mysecret` |
| `job_kubernetes_deploy_production` | `production` | `gitlab-secret/production/project-group/project-5/mysecret` |
| `job_kubernetes_uninstall` | — | `werf dismiss` (manual) |

См. [`.gitlab-ci.yml`](.gitlab-ci.yml).

## Настройка в Stronghold (Terraform)

### Политика KV: environment + project_path

[`terraform/05-gitlab.tf`](../../../terraform/05-gitlab.tf):

```19:27:terraform/05-gitlab.tf
resource "vault_policy" "read_by_project_env" {
  name   = "per-project-access-with-env"
  policy = <<EOT
path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.environment}}/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
EOT
}
```

### Секреты dev и production для project-5

```104:126:terraform/05-gitlab.tf
resource "vault_kv_secret_v2" "gitlab-secret-project-5-production" {
  mount = vault_mount.gitlab-secret.path
  name  = "production/project-group/project-5/mysecret"
  data_json = jsonencode(
    {
      LOGIN    = "prod-my-secret-user"
      PASSWORD = "prod-secret-password-for-project-5"
      DATABASE = "prod-my-secret-database"
    }
  )
}
resource "vault_kv_secret_v2" "gitlab-secret-project-5-dev" {
  mount = vault_mount.gitlab-secret.path
  name  = "dev/project-group/project-5/mysecret"
  data_json = jsonencode(
    {
      LOGIN    = "dev-my-secret-user"
      PASSWORD = "dev-secret-password-for-project-5"
      DATABASE = "prod-my-secret-database"
    }
  )
}
```

### Политика деплоя в Kubernetes

[`terraform/06-gitlab-deploy.tf`](../../../terraform/06-gitlab-deploy.tf):

```34:41:terraform/06-gitlab-deploy.tf
resource "vault_policy" "deploy_policy" {
  name   = "project-deploy-policy"
  policy = <<EOT
path "kubernetes/creds/deploy_role" {
  capabilities = ["update"]
}
EOT
}
```

### JWT-роль: чтение секретов + kube-токен

[`terraform/07-werf-secret-key.tf`](../../../terraform/07-werf-secret-key.tf):

```52:63:terraform/07-werf-secret-key.tf
resource "vault_jwt_auth_backend_role" "role_project_5_example" {
  backend        = vault_jwt_auth_backend.gitlab.path
  role_name      = "role-can-read-secret-and-deploy"
  token_policies = [vault_policy.read_by_project_env.name, vault_policy.deploy_policy.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = { "project_path" : "project_path", "environment" : "environment" }

  user_claim = "project_path"
  role_type  = "jwt"
  token_ttl  = 300
}
```

В чарте: [`.helm/templates/secret.yaml`](.helm/templates/secret.yaml), [`deployment.yaml`](.helm/templates/deployment.yaml).

## См. также

- [project-1](../project-1/README.md) — JWT и роли `read-by-gitlab-project*`
- [project-3](../project-3/README.md) — kubernetes secrets engine
