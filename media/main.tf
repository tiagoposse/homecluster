
resource "helm_release" "media" {
  name       = local.name
  repository = local.repo
  chart      = local.chart
  version    = local.version
  namespace  = local.namespace
  values     = local.values

  depends_on = [kubernetes_persistent_volume_claim.plex-pvc, kubernetes_persistent_volume.plex-pv]
}

resource "kubernetes_namespace" "media" {
  metadata {
    name = local.namespace
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

locals {
  name       = "media"
  repo       = "https://charts.tiagoposse.com"
  chart      = "kube-plex"
  version    = "0.2.7"
  namespace  = "media"
  values = [
    file("values.yml")
  ]
}

terraform {
  backend "pg" {}
}

provider "helm" {}
provider "kubernetes" {}