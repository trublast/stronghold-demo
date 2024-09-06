variable "stronghold_addr" {
  type    = string
}

variable "oidc_mount" {
  type    = string
  default = "oidc_deckhouse"
}

variable "oidc_role" {
  type    = string
  default = "deckhouse_dex_authenticated"
}

variable "oidc_deckhouse_id" {
  type    = string
}
