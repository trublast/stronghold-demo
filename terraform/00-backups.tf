# resource "vault_raft_snapshot_agent_config" "local_backups" {
#   name             = "local"
#   interval_seconds = 300
#   retain           = 7
#   path_prefix      = "/tmp/snap"
#   storage_type     = "local"

#   # Storage Type Configuration
#   local_max_space = 10000000
# }

resource "vault_raft_snapshot_agent_config" "s3_backups" {
  name             = "my-s3-backup"
  interval_seconds = 3600 # 1h
  retain           = 7
  path_prefix      = "/stronghold"
  storage_type     = "aws-s3"

  # Storage Type Configuration
  aws_s3_endpoint = var.aws_s3_endpoint
  aws_s3_bucket         = "backups"
  aws_s3_region         = "ru"
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
}

