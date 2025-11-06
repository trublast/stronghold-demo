## Что в этом примере

1. Аутентификация с помощью роли `role-can-read-secret-and-deploy`
2. Получение JWT токена кубернетес, с помощью которого производится деплой
3. Получение секретов из Stronghold, которые будут установлены при деплое
4. Деплой

Секреты получаются по шаблону `${CI_ENVIRONMENT_SLUG}/${CI_PROJECT_PATH}` и помещаются в Secret Kubernetes
через `WERF_SET_*`. Секрет подключается к `Deployment` через `envFrom`. Для разных проектов и окружений
получение происходит из разных мест. Секрет подключается к `Deployment` через `envFrom`.
Политика дает права только на определенные пути в Stronhold

```
# Политика для секретов с учетом project + env

resource "vault_policy" "read_by_project_env" {
  name = "per-project-access-with-env"
  policy = <<EOT
path "gitlab-secret/data/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.environment}}/{{identity.entity.aliases.${vault_jwt_auth_backend.gitlab.accessor}.metadata.project_path}}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_policy" "deploy_policy" {
  name = "project-deploy-policy"
  policy = <<EOT
path "kubernetes/creds/deploy_role" {
  capabilities = ["update"]
}
EOT
}

# Role for reading secret by env and deploy to k8s

resource "vault_jwt_auth_backend_role" "role_project_5_example" {
  backend         = vault_jwt_auth_backend.gitlab.path
  role_name       = "role-can-read-secret-and-deploy"
  token_policies  = [vault_policy.read_by_project_env.name,vault_policy.deploy_policy.name]  # Used 2 policies

  bound_audiences = ["gitlab-access-aud"]
  claim_mappings  = {"project_path": "project_path", "environment": "environment"}

  user_claim      = "project_path"
  role_type       = "jwt"
  token_ttl       = 300
}
```
