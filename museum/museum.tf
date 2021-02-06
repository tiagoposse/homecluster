resource "helm_release" "museum" {
  name       = "museum"
  repository = "https://chartmuseum.github.io/charts"
  chart      = "chartmuseum"
  version    = "2.14.2"
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