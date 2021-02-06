
resource "kubernetes_service_account" "build-sa" {
  metadata {
    name = "drone-build-sa"
    namespace = local.releases.runner.namespace
  }
}

# resource "kubernetes_cluster_role" "cr_build" {
#   metadata {
#     name = "drone-build"
#   }

#   rule {
#     api_groups = ["*"]
#     resources  = ["*"]
#     verbs      = ["*"]
#   }
# }

resource "kubernetes_cluster_role_binding" "crb_build" {
  metadata {
    name = "drone-build"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "drone-build-sa"
    namespace = local.releases.runner.namespace
  }
}

resource "kubernetes_persistent_volume_claim" "data-pvc" {
  metadata {
    name = "drone-pvc"
    namespace = local.releases.drone.namespace
  }

  spec {
    storage_class_name = "local-path-retain"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "8Gi"
      }
    }
  }

  wait_until_bound = false
}