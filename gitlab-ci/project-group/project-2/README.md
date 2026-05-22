# Изоляция секретов по пути проекта

Тот же приём JWT + KV, что в [project-1](../project-1/README.md), но для отдельного GitLab-проекта. Показывает, что политика Stronghold привязана к `project_path` из JWT: `project-2` не может прочитать секрет `project-group/project-1/mysecret`.

## Что демонстрирует пример

- Секреты лежат в Stronghold по пути, совпадающему с `CI_PROJECT_PATH`, а не в переменных GitLab.
- Доступ изолирован на уровне политики: каждый проект видит только свой префикс в `gitlab-secret/`.

## Jobs в `.gitlab-ci.yml`

| Job | Роль Stronghold | Путь к секрету |
|-----|-----------------|----------------|
| `job_with_secrets` | `read-by-gitlab-project` | `gitlab-secret/${CI_PROJECT_PATH}/mysecret` → `gitlab-secret/project-group/project-2/mysecret` |

См. [`.gitlab-ci.yml`](.gitlab-ci.yml).

## Настройка в Stronghold (Terraform)

Общие роли и политики — как в [project-1](../project-1/README.md#настройка-в-stronghold-terraform), файл [`terraform/05-gitlab.tf`](../../../terraform/05-gitlab.tf).

### Роль и политика (общие для project-1 и project-2)

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

### Секрет только для project-2

```80:89:terraform/05-gitlab.tf
resource "vault_kv_secret_v2" "gitlab-secret-project-2" {
  mount = vault_mount.gitlab-secret.path
  name  = "project-group/project-2/mysecret"
  data_json = jsonencode(
    {
      password = "secret-password-for-project-2"
    }
  )
}
```

При запуске пайплайна в JWT будет `project_path: project-group/project-2` — политика разрешит чтение только этого префикса, не `project-group/project-1/...`.
