## Что в этом примере

### job_kubernetes_deploy

1. Аутентифицируется в Stronghold
2. Получает JWT сервис-аккаунта Kubernetes на освновании роли `kubernetes/creds/deploy_role` для взаимодействия с API Kubernetes
3. Выполняет деплой helm-чарта

### job_kubernetes_uninstall

1. Аутентифицируется в Stronghold
2. Получает JWT сервис-аккаунта Kubernetes на освновании роли `kubernetes/creds/deploy_role` для взаимодействия с API Kubernetes
3. Выполняет деинсталляцию helm-чарта


## Политика доступа

Только для project-3

```
resource "vault_jwt_auth_backend_role" "deploy_role" {
  backend         = vault_jwt_auth_backend.gitlab.path
  role_name       = "deploy-from-gitlab"
  token_policies  = [vault_policy.deploy_policy.name]

  bound_audiences = ["gitlab-access-aud"]
  bound_claims = {
    "project_path" = "project-group/project-3"
  }
  claim_mappings  = {"project_path": "project_path"}

  user_claim      = "project_path"
  role_type       = "jwt"
  token_ttl       = 300
}
```
