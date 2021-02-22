module "vault" {
  vault = {
    policies = local.policies
    secrets = []
    roles = local.roles
  }

  source = "../../templates/vault"
}

resource "kubernetes_service_account" "photos-backup" {
  metadata {
    name = local.job_name
    namespace = local.namespace
  }
}

resource "kubernetes_cron_job" "photos-job" {
  metadata {
    name = local.job_name
    namespace = var.namespace
  }

  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "0 2 * * *"
    starting_deadline_seconds     = 10
    successful_jobs_history_limit = 5


    job_template {
      metadata {}
      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 10
          

        template {
          metadata {
            annotations = {
              "autocert.step.sm/bootstrapper-only" = "true"
              "autocert.step.sm/duration" = "4380h"
              "autocert.step.sm/init-first" = "true"
              "autocert.step.sm/name" = local.job_name
              "vault.hashicorp.com/agent-inject" = "true"
              "vault.hashicorp.com/agent-pre-populate-only" = "true"
              "vault.hashicorp.com/agent-inject-token" = "true"
              "vault.hashicorp.com/ca-cert" = "/var/run/autocert.step.sm/root.crt"
              "vault.hashicorp.com/role" = local.job_name
              "vault.hashicorp.com/agent-inject-secret-credentials" = "kv/data/aws/glacier"
              "vault.hashicorp.com/agent-inject-template-credentials" = <<EOF
[default]
{{- with secret \"kv/data/aws/glacier\" -}}
[remote]
type = s3
provider = AWS
env_auth = false
access_key_id = {{ .Data.data.access_key }}
secret_access_key = {{ .Data.data.secret_key }}
region = {{ .Data.data.region }}
endpoint = {{ .Data.data.bucket_endpoint }}
location_constraint = 
acl = private
server_side_encryption = AES256
storage_class = GLACIER
{{- end -}}
EOF
            }
          }

          spec {
            service_account_name = kubernetes_service_account.photos-backup.metadata.0.name

            container {
              name    = "backup"
              image   = "rclone:1.54"
              command = [
                "/bin/sh",
                "-c",
                "rclone sync --fast-list --checksum . s3://tiagoposse-backup-photos/ --config $CONFIG_PATH"
              ]

              env {
                name = "CONFIG_PATH"
                value = "/vault/secrets/credentials"
              }

              env {
                name = "AWS_PROFILE"
                value = "default"
              }

              env {
                name = "VAULT_ADDR"
                value = "https://vault.vault.svc:8200"
              }

              env {
                name = "VAULT_CACERT"
                value = "/var/run/autocert.step.sm/root.crt"
              }

              env {
                name = "VAULT_TOKEN"
                value = "/vault/secrets/token"
              }

              volume_mount {
                name = "backup"
                mount_path = "/photos"
              }
            }

            volume {
              name = "backup"
              persistent_volume_claim {
                claim_name = "photos-backup-pvc"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "photos-backup-pvc" {
  metadata {
    name = "photos-backup-pvc"
    namespace = var.release.namespace
  }

  spec {
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "200Gi"
      }
    }
    
    volume_name = "backups-photos"
  }

  wait_until_bound = false
}


resource "kubernetes_persistent_volume" "photos-backup-pv" {
  metadata {
    name = "backups-photos"
  }

  spec {
    capacity = {
      storage = "200Gi"
    }
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/nas/mediacenter/data/photos"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "k3s.io/hostname"
            operator = "In"
            values   = ["worker1"]
          }
        }
      }
    }
  }
}
