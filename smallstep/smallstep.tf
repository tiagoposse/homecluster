
resource "helm_release" "smallstep" {
  name       = "zmallstep"
  repository = "https://smallstep.github.io/helm-charts/"
  chart      = "autocert"
  version    = "1.12.3"
  namespace  = "tools"
  values = [
    file("values.yml")
  ]
}

provider "helm" {}
provider "kubernetes" {}

terraform {
  backend "pg" {}
}