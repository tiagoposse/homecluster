
terraform {
  backend "pg" {}
}

provider "vault" {}
provider "kubernetes" {}
provider "helm" {}