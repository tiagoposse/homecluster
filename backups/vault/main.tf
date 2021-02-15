module "vault" {
  vault = {
    policies = local.policies
    secrets = []
    roles = local.roles
  }

  source = "../../templates/vault"
}

resource "kubernetes_service_account" "vault-backup" {
  metadata {
    name = local.job_name
    namespace = var.release.namespace
  }
}

resource "kubernetes_cron_job" "vault-job" {
  metadata {
    name = local.job_name
    namespace = var.release.namespace
  }

  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "0 6 * * *"
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
              "autocert.step.sm/name" = "vault-backup"
              "vault.hashicorp.com/agent-inject" = "true"
              "vault.hashicorp.com/agent-pre-populate-only" = "true"
              "vault.hashicorp.com/agent-inject-token" = "true"
              "vault.hashicorp.com/ca-cert" = "/var/run/autocert.step.sm/root.crt"
              "vault.hashicorp.com/role" = "vault-backup"
            }
          }
          spec {
            service_account_name = kubernetes_service_account.vault-backup.metadata.0.name

            container {
              name    = "backup"
              image   = "curlimages/curl"
              command = [
                "/bin/sh",
                "-c",
                "echo Creating backup $BACKUP_TARGET/vault-$(date +\"%d-%m-%Y-%H-%M\").snap; mkdir -p $BACKUP_TARGET; curl --cacert $VAULT_CACERT --header \"X-Vault-Token: $(cat $VAULT_TOKEN)\" $VAULT_ADDR/v1/sys/storage/raft/snapshot > $BACKUP_TARGET/vault-$(date +\"%d-%m-%Y-%H-%M\").snap; echo FINISHED;"
              ]

              env {
                name = "BACKUP_TARGET"
                value = "/backups"
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
                mount_path = "/backups"
              }
            }

            volume {
              name = "backup"
              persistent_volume_claim {
                claim_name = "vault-backup-pvc"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "vault-backup-pvc" {
  metadata {
    name = "vault-backup-pvc"
    namespace = var.release.namespace
  }

  spec {
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    
    volume_name = "backups-vault"
  }

  wait_until_bound = false
}


resource "kubernetes_persistent_volume" "vault-backup-pv" {
  metadata {
    name = "backups-vault"
  }

  spec {
    capacity = {
      storage = "20Gi"
    }
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/nas/backups/vault"
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
