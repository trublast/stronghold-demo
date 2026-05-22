# Werf: ключ расшифровки и деплой из Stronghold

Расширение [project-3](../project-3/README.md): помимо токена Kubernetes пайплайн забирает `WERF_SECRET_KEY` из KV и расшифровывает `.helm/secret-values.yaml` при `werf converge`. Значения для чарта остаются в git в зашифрованном виде; ключ — только в Stronghold.

## Что демонстрирует пример

- JWT → Stronghold → kube-токен + `WERF_SECRET_KEY` за один вход в `.kube_login`.
- Секреты werf по пути `werf-secret/${CI_PROJECT_PATH}/werf` (шаблон политики по `project_path`).
- Деплой чарта с расшифровкой `secret-values` на лету.

## Jobs в `.gitlab-ci.yml`

| Job | Действие |
|-----|----------|
| `job_kubernetes_deploy` | `.kube_login` (роль `werf-secret-by-gitlab-project`, `WERF_SECRET_KEY`, kube-токен) → `werf converge` |
| `job_kubernetes_uninstall` | тот же `.kube_login` → `werf dismiss` (manual) |

См. [`.gitlab-ci.yml`](.gitlab-ci.yml).

Kube backend и `deploy_policy`: [`terraform/06-gitlab-deploy.tf`](../../../terraform/06-gitlab-deploy.tf).

## Настройка в Stronghold (Terraform)

Файл [`terraform/07-werf-secret-key.tf`](../../../terraform/07-werf-secret-key.tf).

### Mount `werf-secret` и ключ для project-4

```1:17:terraform/07-werf-secret-key.tf
resource "vault_mount" "werf-secret" {
  path        = "werf-secret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "werf_secret" {
  mount               = vault_mount.werf-secret.path
  name                = "project-group/project-4/werf"
  delete_all_versions = true
  data_json = jsonencode(
    {
      WERF_SECRET_KEY = "43d9e7dae581a1400bf85115fc6ed97e"
    }
  )
}
```

### Политика: werf-secret по project_path + kube deploy

```21:31:terraform/07-werf-secret-key.tf
resource "vault_policy" "werf_secret_by_project" {
  name   = "werf-per-project-access"
  policy = <<EOT
path "werf-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
path "kubernetes/creds/deploy_role" {
  capabilities = ["update"]
}
EOT
}
```

### JWT-роль для пайплайна

```35:46:terraform/07-werf-secret-key.tf
resource "vault_jwt_auth_backend_role" "werf_secret_by_project" {
  backend        = vault_jwt_auth_backend.gitlab.path
  role_name      = "werf-secret-by-gitlab-project"
  token_policies = [vault_policy.werf_secret_by_project.name]

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = { "project_path" : "project_path" }

  user_claim = "project_path"
  role_type  = "jwt"
  token_ttl  = 300
}
```

Изоляция по проекту — через шаблон пути в политике, без жёсткого `bound_claims` на `project_path`.

В репозитории: [`.helm/secret-values.yaml`](.helm/secret-values.yaml), [`.helm/templates/secret.yaml`](.helm/templates/secret.yaml).

## См. также

- [project-5](../project-5/README.md) — секреты приложения в pod по GitLab Environment
