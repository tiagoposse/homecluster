locals {
  volumes = {
    plex-data = {
      size = "300Gi"
      path = "/nas/mediacenter/data"
    }
    plex-config = {
      size = "300Gi"
      path = "/nas/mediacenter/config"
    }
    plex-transcode = {
      size = "300Gi"
      path = "/nas/mediacenter/transcode"
    }
  }
}

resource "kubernetes_persistent_volume" "plex-pv" {
  for_each = local.volumes

  metadata {
    name = each.key
  }
  spec {
    capacity = {
      storage = each.value.size
    }
    storage_class_name = "manual"
    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = each.value.path
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

resource "kubernetes_persistent_volume_claim" "plex-pvc" {
  for_each = local.volumes

  metadata {
    name = each.key
    namespace = local.namespace
  }
  spec {
    storage_class_name = "manual"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = each.value.size
      }
    }

    volume_name = kubernetes_persistent_volume.plex-pv[each.key].metadata.0.name
  }
}