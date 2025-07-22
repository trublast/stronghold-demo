resource "vault_jwt_auth_backend" "github" {
    description = "Demo for github"
    path = "github"
    type = "jwt"
    oidc_discovery_url  = "https://token.actions.githubusercontent.com"
    bound_issuer        = "https://token.actions.githubusercontent.com"
}


resource "vault_jwt_auth_backend_role" "role_for_github" {
  backend         = vault_jwt_auth_backend.github.path
  role_name       = "stronghold-demo"
  token_policies  = ["deckhouse_administrators"]

  bound_audiences = ["github-aud"]
  bound_claims = {
    "repository": "trublast/stronghold-demo"
  }

  user_claim      = "actor"
  role_type       = "jwt"
  token_ttl       = 300
}


resource "vault_kv_secret_v2" "github_secret" {
  mount                      = "secret"
  name                       = "stronghold/mysecret"
  data_json                  = jsonencode(
    {
        AWS_ACCESS_KEY_ID          = "dev-my-secret-user"
        AWS_SECRET_ACCESS_KEY       = "dev-secret-password-for-project-5"
    }
  )
}
