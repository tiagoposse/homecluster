
resource "helm_release" "dash" {
  name       = local.name
  repository = local.repo
  chart      = local.chart
  version    = local.version
  namespace  = local.namespace
  values     = local.values
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.namespace
  }
}

locals {
  name       = "dashboard"
  chart      = "kubernetes-dashboard"
  repo = "https://kubernetes.github.io/dashboard"
  version    = "3.0.0"
  namespace = "dashboard"
  values = [
    file("values.yml")
  ]
}

provider "helm" {}
provider "kubernetes" {}

terraform {
  backend "pg" {}
}