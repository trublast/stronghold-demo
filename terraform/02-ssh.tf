resource "vault_mount" "ssh_backend" {
    type = "ssh"
    path = "ssh"
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
    backend = vault_mount.ssh_backend.path
    generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh_access" {
    name                    = "ssh_access"
    backend                 = vault_mount.ssh_backend.path
    key_type                = "ca"
    allow_user_certificates = true
    allowed_extensions      = "permit-pty,permit-port-forwarding"
    default_extensions      = {permit-pty=""}
    allowed_users           = "*"
    ttl                     = "1800"
}

resource "vault_policy" "ssh_access" {
  name = "ssh_access"
  policy = file("policies/ssh.hcl")
}

# ssh-keygen -f demo
# stronghold login -method=oidc -path=oidc_deckhouse -no-print
# echo -n 'cert-authority,principals="connect" ' && stronghold read ssh/config/ca --format=json | jq -r .data.public_key
# stronghold write ssh/sign/ssh_access public_key=@demo.pub valid_principals=connect -format=json | jq -r .data.signed_key | sed '/^$/d' > demo-cert.pub && chmod 0600 demo-cert.pub
# ssh demo-master-0 -l demo -i demo
