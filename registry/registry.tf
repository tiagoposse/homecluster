
resource "helm_release" "registry" {
  name       = local.release.name
  repository = local.release.repository
  chart      = local.release.chart
  version    = local.release.version
  namespace  = local.release.namespace
  values     = local.release.values
}

locals {
  release = {
    name       = "registry"
    repository = "https://charts.helm.sh/stable"
    chart      = "docker-registry"
    version    = "1.9.6"
    namespace  = "tools"
    values = [
      file("values.yml")
    ]
  }

terraform {
  backend "pg" {}
}

provider "helm" {}
provider "kubernetes" {}