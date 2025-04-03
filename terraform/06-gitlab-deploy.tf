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
  service_account_name = "deckhouse"
  token_max_ttl                 = 43200
  token_default_ttl             = 1800
}


resource "vault_jwt_auth_backend_role" "deploy_role" {
  backend         = vault_jwt_auth_backend.gitlab.path
  role_name       = "deploy-from-gilab"
  token_policies  = [vault_policy.deploy_policy.name]

  bound_audiences = ["gilab-access-aud"]
  bound_claims = {
    "project_path" = "project-group/project-3"
  }
  claim_mappings  = {"project_path": "project_path"}

  user_claim      = "project_path"
  role_type       = "jwt"
  token_ttl       = 300
}

resource "vault_policy" "deploy_policy" {
  name = "project-deploy-policy"
  policy = <<EOT
path "kubernetes/creds/deploy_role" {
  capabilities = ["update"]
}
EOT
}
