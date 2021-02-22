resource "kubernetes_namespace" "backups" {
  metadata {
    name = "backups"
    
    labels = {
      "autocert.step.sm" = "enabled"
    }
  }
}

module "vault-backup" {
  source = "./vault"

  release = jsondecode(file("../secrets/terraform.tfvars.json")).release
}