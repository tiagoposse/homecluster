resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_mount" "pki" {
  path = "pki"
  type = "pki"
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds = 86400
}

resource "vault_mount" "secrets" {
  path = "kv"
  type = "kv-v2"
}

resource "vault_kubernetes_auth_backend_config" "config" {
  backend = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://192.168.178.48:6443"

  nested_block {
    kubernetes_ca_cert = data.kubernetes_secret.sa.data["ca.crt"]
    token_reviewer_jwt = data.kubernetes_secret.sa.data.token
  }
}

data "kubernetes_service_account" "vault-sa" {
  metadata {
    name = var.release.name
    namespace = var.release.namespace
  }
}

data "kubernetes_secret" "sa" {
  metadata {
    name = data.kubernetes_service_account.vault-sa.default_secret_name
    namespace = var.release.namespace
  }
}

terraform {
  backend "pg" {}
}

variable "release" {}

provider "vault" {}
provider "kubernetes" {}
