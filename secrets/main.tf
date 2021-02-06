
resource "helm_release" "vault" {
  name       = local.release.name
  namespace  = local.release.namespace
  chart      = local.release.chart
  repository = local.release.repo
  version    = local.release.version
  values     = local.release.values

  depends_on = [kubernetes_cluster_role_binding.vault]
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.release.namespace
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

locals {
  release = merge(var.release, { values = [file("values.yml")] })
}

variable "release" {}
variable "config" {}

terraform {
  backend "pg" {}
}

provider "kubernetes" {}
provider "helm" {}