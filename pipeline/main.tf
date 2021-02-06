
resource "kubernetes_namespace" "drone" {
  metadata {
    name = local.releases.drone.namespace
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

resource "kubernetes_namespace" "runner" {
  metadata {
    name = local.releases.runner.namespace
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

module "vault" {
  source = "../templates/vault"

  vault = {
    policies = local.policies
    secrets = local.secrets
    roles = local.roles
  }
}

resource "helm_release" "apps" {
  for_each = tomap(local.releases)

  name       = each.value.name
  namespace  = each.value.namespace
  chart      = each.value.chart
  repository = each.value.repo
  version    = each.value.version
  values     = each.value.values

  depends_on = [module.vault]
}

locals {
  releases = {
    drone = {
      name       = "drone"
      repo       = "https://charts.tiagoposse.com"
      chart      = "drone"
      version    = "0.1.7"
      namespace  = "drone"
      values = [
        file("helm/drone-values.yml")
      ]
    }

    pathschanged = {
      name       = "drone-pathschanged"
      repo       = "https://charts.tiagoposse.com"
      chart      = "drone-pathschanged"
      version    = "0.2.0"
      namespace  = "drone"
      values = [
        file("helm/pathschanged-values.yml")
      ]
    }

    runner = {
      name       = "drone-runner"
      repo       = "https://charts.tiagoposse.com"
      chart      = "drone-runner-kube"
      version    = "0.1.4"
      namespace  = "builds"
      values = [
        file("helm/runner-values.yml")
      ]
    }
  }
}

terraform {
  required_version = ">= 0.13"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.2"
    }
  }

  backend "pg" {}
}

provider "kubernetes" {}
provider "helm" {}