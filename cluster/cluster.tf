
resource "kubernetes_storage_class" "sc" {
  metadata {
    name = "local-path-retain"
  }
  storage_provisioner = "rancher.io/local-path"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

resource "kubernetes_namespace" "tools" {
  metadata {
    name = "tools"

    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

provider "kubernetes" {}
provider "helm" {}

terraform {
  backend "pg" {}
}