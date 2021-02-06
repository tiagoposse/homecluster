
resource "kubernetes_namespace" "ingress" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "ingress" {
  name       = local.name
  repository = local.repo
  chart      = local.chart
  version    = local.version
  namespace  = local.namespace
  values     = local.values
}

locals {
  name       = "ingress"
  repo       = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "3.23.0"
  namespace  = "ingress"
  values = [
    file("values.yml")
  ]
}

provider "helm" {}
provider "kubernetes" {}

terraform {
  backend "pg" {}
}
