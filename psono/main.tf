
resource "kubernetes_namespace" "psono" {
  metadata {
    name = local.release.namespace
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

resource "helm_release" "psono" {
  name       = local.release.name
  repository = local.release.repository
  chart      = local.release.chart
  version    = local.release.version
  namespace  = local.release.namespace
  values     = local.release.values

  depends_on = [kubernetes_persistent_volume_claim.backup-pvc, module.vault]
}


module "vault" {
  source = "../templates/vault"

  vault = {
    policies = local.policies
    secrets = local.secrets
    roles = local.roles
  }
}

resource "kubernetes_persistent_volume_claim" "backup-pvc" {
  metadata {
    name = "psono-backup-pvc"
    namespace = local.release.namespace
  }

  spec {
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    
    volume_name = "backups-psono"
  }

  wait_until_bound = false
}


resource "kubernetes_persistent_volume" "backup-pv" {
  metadata {
    name = "backups-psono"
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/nas/backups/psono"
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

terraform {
  backend "pg" {}
}

provider "helm" {}
provider "kubernetes" {}