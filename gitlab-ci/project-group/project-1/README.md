# JWT-аутентификация GitLab CI в Stronghold

Пример показывает, как пайплайн получает секреты из Stronghold «на лету», без переменных GitLab и без хранения в репозитории. GitLab выпускает подписанный JWT на каждую job; Stronghold выдаёт краткоживущий токен с политикой, согласованной с claims в JWT. Секреты в KV могут быть статическими или динамическими — их не нужно вручную ротировать в CI.

## Что демонстрирует пример

- Аутентификация job в Stronghold через `id_tokens` и `auth/gitlab/login`.
- Доступ к секретам только в пределах пути проекта (`read-by-gitlab-project`).
- Разделение секретов по GitLab Environment (`read-by-gitlab-project-env`).

## Jobs в `.gitlab-ci.yml`

| Job | Роль Stronghold | Путь к секрету |
|-----|-----------------|----------------|
| `job_with_secrets` | `read-by-gitlab-project` | `gitlab-secret/${CI_PROJECT_PATH}/mysecret` |
| `job_with_secrets_for_production` | `read-by-gitlab-project-env` | `gitlab-secret/${CI_ENVIRONMENT_SLUG}/${CI_PROJECT_PATH}/mysecret` (environment: `production`) |

См. [`.gitlab-ci.yml`](.gitlab-ci.yml).

## Как это работает

При старте job GitLab создаёт JWT с метаданными пайплайна (проект, ветка, пользователь, environment и т.д.). Скрипт не может подменить claims — только передать токен в Stronghold. После `auth/gitlab/login` job читает поле из KV через `d8 stronghold kv get`.

Фрагмент payload JWT (полный набор полей зависит от версии GitLab):

```json
{
  "project_path": "project-group/project-1",
  "ref": "main",
  "ref_protected": "true",
  "environment": "production",
  "aud": "gitlab-access-aud",
  "iss": "https://gitlab.demo-cluster.ru"
}
```

## Настройка в Stronghold (Terraform)

Конфигурация demo: [`terraform/05-gitlab.tf`](../../../terraform/05-gitlab.tf).

### JWT auth method для GitLab

```1:7:terraform/05-gitlab.tf
resource "vault_jwt_auth_backend" "gitlab" {
  description        = "Demo for gitlab"
  path               = "gitlab"
  type               = "jwt"
  oidc_discovery_url = "https://gitlab.demo-cluster.ru"
  bound_issuer       = "https://gitlab.demo-cluster.ru"
}
```

Эквивалент через CLI: `stronghold write auth/gitlab/config oidc_discovery_url=... bound_issuer=...`.

### Политика и роль: секрет по пути проекта

Используется в `job_with_secrets`.

```10:42:terraform/05-gitlab.tf
resource "vault_policy" "read_by_project" {
  name   = "per-project-access"
  policy = <<EOT
path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "role_by_project" {
  backend        = vault_jwt_auth_backend.gitlab.path
  role_name      = "read-by-gitlab-project"
  token_policies = [vault_policy.read_by_project.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = { "project_path" : "project_path" }

  user_claim = "project_path"
  role_type  = "jwt"
  token_ttl  = 300
}
```

### Политика и роль: секрет по проекту и environment

Используется в `job_with_secrets_for_production` (claim `environment` появляется при `environment:` в job).

```19:57:terraform/05-gitlab.tf
resource "vault_policy" "read_by_project_env" {
  name   = "per-project-access-with-env"
  policy = <<EOT
path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.environment}}/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_jwt_auth_backend_role" "role_by_project_env" {
  backend        = vault_jwt_auth_backend.gitlab.path
  role_name      = "read-by-gitlab-project-env"
  token_policies = [vault_policy.read_by_project_env.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = { "project_path" : "project_path", "environment" : "environment" }

  user_claim = "project_path"
  role_type  = "jwt"
  token_ttl  = 300
}
```

### KV mount и секреты для этого проекта

```61:101:terraform/05-gitlab.tf
resource "vault_mount" "gitlab-secret" {
  path        = "gitlab-secret"
  type        = "kv"
  options     = { version = "2" }
  description = "Secrets for gitlab"
}

resource "vault_kv_secret_v2" "gitlab-secret-project-1" {
  mount = vault_mount.gitlab-secret.path
  name  = "project-group/project-1/mysecret"
  data_json = jsonencode(
    {
      password = "secret-password-for-project-1"
    }
  )
}

resource "vault_kv_secret_v2" "gitlab-secret-project-1-production" {
  mount = vault_mount.gitlab-secret.path
  name  = "production/project-group/project-1/mysecret"
  data_json = jsonencode(
    {
      password = "secret-password-for-project-1-production"
    }
  )
}
```

Дополнительно роли можно ограничить `bound_claims` (ветка, `project_id`, protected ref) — пример для деплоя в Kubernetes: [`terraform/06-gitlab-deploy.tf`](../../../terraform/06-gitlab-deploy.tf).

## См. также

- [project-2](../project-2/README.md) — изоляция доступа между проектами
- [project-3](../project-3/README.md) — временный токен Kubernetes
