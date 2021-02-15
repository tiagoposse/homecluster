module "vault-backup" {
  source = "./vault"

  release = jsondecode(file("../secrets/terraform.tfvars.json")).release
}