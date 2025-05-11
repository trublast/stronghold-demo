resource "vault_namespace" "namespace_ns1" {
  path = "ns1"
}

resource "vault_namespace" "namespace_ns2" {
  path = "ns2"
}

resource "vault_namespace" "namespace_ns1_a1" {
  namespace = vault_namespace.namespace_ns1.path_fq
  depends_on  = [vault_namespace.namespace_ns1]
  path = "a1"
}

resource "vault_namespace" "namespace_ns1_a2" {
  namespace = vault_namespace.namespace_ns1.path_fq
  depends_on  = [vault_namespace.namespace_ns1]
  path = "a2"
}

resource "vault_namespace" "namespace_ns1_a1_b1" {
  namespace = vault_namespace.namespace_ns1_a1.path_fq
  depends_on  = [vault_namespace.namespace_ns1_a1]
  path = "b1"
}

resource "vault_namespace" "namespace_ns2_a1" {
  namespace = vault_namespace.namespace_ns2.path_fq
  depends_on  = [vault_namespace.namespace_ns2]
  path = "a1"
}

resource "vault_policy" "admin-ns1" {
  namespace = vault_namespace.namespace_ns1.path_fq
  name = "admin"
  policy = file("policies/admin.hcl")
}

resource "vault_policy" "user-ns1" {
  namespace = vault_namespace.namespace_ns1.path_fq
  name = "user"
  policy = file("policies/user.hcl")
}

resource "vault_policy" "admin-ns2" {
  namespace = vault_namespace.namespace_ns2.path_fq
  name = "admin"
  policy = file("policies/admin.hcl")
}

resource "vault_auth_backend" "ns1_userpass" {
  namespace = vault_namespace.namespace_ns1.path_fq
  type = "userpass"
  tune {
      listing_visibility = "unauth"
  }
}

resource "vault_generic_endpoint" "ns1-admin" {
  namespace = vault_namespace.namespace_ns1.path_fq
  depends_on           = [vault_auth_backend.ns1_userpass]
  path                 = "auth/userpass/users/admin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["admin"],
  "password": "Password-1"
}
EOT
}

resource "vault_generic_endpoint" "ns1-user" {
  namespace = vault_namespace.namespace_ns1.path_fq
  depends_on           = [vault_auth_backend.ns1_userpass]
  path                 = "auth/userpass/users/user"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["user"],
  "password": "Password-1"
}
EOT
}


resource "vault_jwt_auth_backend" "gitlab_in_ns2" {
    namespace = vault_namespace.namespace_ns2.path_fq
    description = "Login to NS2 via Gitlab"
    path = "gitlab"
    type = "oidc"
    oidc_client_id      = var.gitlab_oidc_client_id
    oidc_client_secret  = var.gitlab_oidc_client_secret
    default_role = "admin"
    oidc_discovery_url  = "https://gitlab.demo-cluster.ru"
    bound_issuer        = "https://gitlab.demo-cluster.ru"
    tune {
        listing_visibility = "unauth"
    }
}

resource "vault_jwt_auth_backend_role" "ns2_gitlab_role_admin" {
  namespace = vault_namespace.namespace_ns2.path_fq
  backend         = vault_jwt_auth_backend.gitlab_in_ns2.path
  role_name       = "admin"
  bound_audiences = [var.gitlab_oidc_client_id]
  token_policies  = [vault_policy.admin-ns2.name]
  user_claim      = "sub"
  role_type       = "oidc"
  token_ttl       = 300
  allowed_redirect_uris = ["https://stronghold.stronghold-demo.flant.dev/ui/stronghold/auth/gitlab/oidc/callback"]
}



resource "vault_mount" "secret-in-ns1" {
  namespace = vault_namespace.namespace_ns1.path_fq
  path        = "secret-in-ns1"
  type        = "kv"
  options     = { version = "2" }
}

resource "vault_mount" "secret-in-ns2" {
  namespace = vault_namespace.namespace_ns2.path_fq
  path        = "secret-in-ns2"
  type        = "kv"
  options     = { version = "2" }
}

resource "vault_mount" "secret-in-ns1-a1" {
  namespace = vault_namespace.namespace_ns1_a1.path_fq
  path        = "secret-in-ns1-a1"
  type        = "kv"
  options     = { version = "2" }
}

resource "vault_mount" "secret-in-ns1-a1-b1" {
  namespace = vault_namespace.namespace_ns1_a1_b1.path_fq
  path        = "secret-in-ns1-a1-b1"
  type        = "kv"
  options     = { version = "2" }
}
