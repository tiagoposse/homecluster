
resource "helm_release" "registry" {
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