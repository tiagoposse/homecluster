
locals {
  job_name = "vault-backup"

  policies = {
    vault-backup = <<EOT
path "/sys/storage/raft/snapshot" {
  capabilities = ["read"]
}
EOT
  }

  roles = [
    {
      name = local.job_name
      namespaces = [var.release.namespace]
      sas = [local.job_name]
      policies = ["vault-backup"]
    }
  ]
}

variable "release" {}