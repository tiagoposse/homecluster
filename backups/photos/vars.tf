
locals {
  job_name = "photos-backup"
  namespace = "backups"

  policies = {
    photos-backup = <<EOT
path "/kv/data/aws/glacier" {
  capabilities = ["read"]
}
EOT
  }

  roles = [
    {
      name = local.job_name
      namespaces = [var.release.namespace]
      sas = [local.job_name]
      policies = ["photos-backup"]
    }
  ]
}
