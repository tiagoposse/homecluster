
resource "helm_release" "app" {
  name       = local.name
  repository = local.repo
  chart      = local.chart
  version    = local.version
  namespace  = local.namespace
  values     = local.values
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = local.namespace
  }
}

locals {
  name = "certmanager"
  namespace = "cert-manager"
  chart = "cert-manager"
  repo = "https://charts.jetstack.io"
  version = "1.0.4"
  values = [
    file("values.yml")
  ]
}

resource "kubectl_manifest" "prod-issuer" {
    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: cluster-issuer
spec:
  acme:
    email: tiagoposse@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-issue
    solvers:
    - http01:
       ingress:
         class: nginx
YAML

    depends_on = [helm_release.app]
}

resource "kubectl_manifest" "staging-issuer" {
    yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: staging-issuer
spec:
  acme:
    email: tiagoposse@gmail.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-issue
    solvers:
    - http01:
       ingress:
         class: nginx
YAML

    depends_on = [helm_release.app]
}


provider "helm" {}
provider "kubernetes" {}
provider "kubectl" {}

terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }

  backend "pg" {}
}
