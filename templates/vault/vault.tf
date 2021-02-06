
data "vault_auth_backend" "kubernetes" {
  path = "kubernetes"
}

variable "vault" {
  default = {
    secrets = []
    roles = []
    policies = {}
  }
}

resource "vault_policy" "policies" {
  for_each = var.vault.policies
  name = each.key

  policy = each.value
}

resource "vault_generic_secret" "secrets" {
  for_each = {
    for key, value in var.vault.secrets : key => value
  }

  path = each.value.path

  data_json = jsonencode(each.value.values)
  lifecycle {
    ignore_changes = [data_json]
  }
}

resource "vault_kubernetes_auth_backend_role" "roles" {
  for_each = {
    for key, role in var.vault.roles : role.name => role
  }

  backend                          = data.vault_auth_backend.kubernetes.path
  role_name                        = each.value.name
  bound_service_account_names      = each.value.sas
  bound_service_account_namespaces = each.value.namespaces
  token_ttl                        = 3600
  token_policies                   = each.value.policies
}