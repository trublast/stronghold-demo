provider "vault" {
  address = var.stronghold_addr
  auth_login_oidc {
    role = var.oidc_role
    mount = var.oidc_mount
  }
}
