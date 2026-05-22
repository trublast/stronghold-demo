variable "stronghold_addr" {
  type = string
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
  type = string
}

variable "stronghold_token" {
  type = string
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "aws_s3_endpoint" {
  type = string
}


variable "gitlab_oidc_client_id" {
  type = string
}

variable "gitlab_oidc_client_secret" {
  type = string
}
