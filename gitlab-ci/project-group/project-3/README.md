# Деплой в Kubernetes с временным токеном сервис-аккаунта

Пайплайн аутентифицируется в Stronghold по JWT, затем запрашивает у secrets engine Kubernetes краткоживущий токен SA и передаёт его в werf (`WERF_KUBE_TOKEN`). Учётные данные кластера не хранятся в GitLab и не коммитятся в git.

## Что демонстрирует пример

- JWT GitLab → токен Stronghold → динамический `service_account_token` для API Kubernetes.
- Деплой и удаление релиза через `werf converge` / `werf dismiss`.
- Ограничение роли JWT только для проекта `project-group/project-3` (`bound_claims`).

## Jobs в `.gitlab-ci.yml`

| Job | Действие |
|-----|----------|
| `job_kubernetes_deploy` | `.kube_login` → `werf converge` |
| `job_kubernetes_uninstall` | `.kube_login` → `werf dismiss` (manual) |

Шаблон `.kube_login`: роль `deploy-from-gitlab`, затем `kubernetes/creds/deploy_role` (namespace `d8-system`). См. [`.gitlab-ci.yml`](.gitlab-ci.yml).

JWT auth method GitLab: [`terraform/05-gitlab.tf`](../../../terraform/05-gitlab.tf).

## Настройка в Stronghold (Terraform)

Файл [`terraform/06-gitlab-deploy.tf`](../../../terraform/06-gitlab-deploy.tf).

### Kubernetes secrets engine и роль выдачи токена SA

```1:15:terraform/06-gitlab-deploy.tf
resource "vault_kubernetes_secret_backend" "config" {
  path                      = "kubernetes"
  description               = "kubernetes secrets engine description"
  default_lease_ttl_seconds = 43200
  max_lease_ttl_seconds     = 86400
}

resource "vault_kubernetes_secret_backend_role" "deploy_role" {
  backend                       = vault_kubernetes_secret_backend.config.path
  name                          = "deploy_role"
  allowed_kubernetes_namespaces = ["*"]
  service_account_name          = "deckhouse"
  token_max_ttl                 = 43200
  token_default_ttl             = 1800
}
```

### Политика: право запросить kube-токен

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

### JWT-роль только для project-3

```18:32:terraform/06-gitlab-deploy.tf
resource "vault_jwt_auth_backend_role" "deploy_role" {
  backend        = vault_jwt_auth_backend.gitlab.path
  role_name      = "deploy-from-gitlab"
  token_policies = [vault_policy.deploy_policy.name]

  bound_audiences = ["gitlab-access-aud"]
  bound_claims = {
    "project_path" = "project-group/project-3"
  }
  claim_mappings = { "project_path" : "project_path" }

  user_claim = "project_path"
  role_type  = "jwt"
  token_ttl  = 300
}
```

Секреты приложения из `gitlab-secret` в этом примере не используются — только доступ к API кластера.

## См. также

- [project-4](../project-4/README.md) — добавление `WERF_SECRET_KEY` и werf secret-values
