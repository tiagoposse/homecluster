
data "vault_auth_backend" "approle" {
  path = "approle"
}

resource "vault_approle_auth_backend_role" "drone-vault" {
  backend        = data.vault_auth_backend.approle.path
  role_name      = "drone-vault"
  token_policies = ["drone-vault"]
  secret_id_num_uses = 0
  token_num_uses = 0
}

resource "vault_approle_auth_backend_role_secret_id" "id" {
  backend   = data.vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.drone-vault.role_name
}


locals {
  policies = {
    drone-vault = <<EOT
path "kv/*" {
  capabilities = ["create", "update", "list", "read"]
}
path "auth/approle/role/*" {
  capabilities = ["create", "update", "list", "read"]
}
path "/auth/kubernetes/role/*" {
  capabilities = ["create", "update", "list", "read"]
}
path "sys/policies/acl/*" {
  capabilities = ["create", "update", "list", "read"]
}
path "kv/data/drone/vault" {
  capabilities = ["create", "update", "list", "read"]
}
path "auth/token/create" {
  capabilities = ["update"]
}
path "sys/auth" {
  capabilities = ["read"]
}
EOT

  drone = <<EOT
path "kv/data/drone/*" {
  capabilities = ["read"]
}
EOT

  drone-build = <<EOT
path "kv/data/tf-state" {
  capabilities = ["read"]
}
path "kv/data/drone/vault" {
  capabilities = ["read"]
}
EOT

  drone-runner = <<EOT
path "kv/data/drone/rpc" {
  capabilities = ["read"]
}
EOT

  drone-pathschanged =  <<EOT
path "kv/data/drone/pathschanged" {
  capabilities = ["read"]
}
path "kv/data/drone/rpc" {
  capabilities = ["read"]
}
EOT
  }

  roles = [
    {
      name = local.releases.drone.name
      namespaces = [local.releases.drone.namespace]
      sas = ["default"]
      policies = [local.releases.drone.name]
    },
    {
      name = local.releases.runner.name
      namespaces = [local.releases.runner.namespace]
      sas = [local.releases.runner.name]
      policies = [local.releases.runner.name]
    },
    {
      name = "drone-build"
      namespaces = [local.releases.runner.namespace]
      sas = ["drone-build-sa"]
      policies = ["drone-build"]
    },
    {
      name = local.releases.pathschanged.name
      namespaces = [local.releases.pathschanged.namespace]
      sas = [local.releases.pathschanged.name]
      policies = ["drone-pathschanged"]
    }
  ]

  secrets = [
    {
      path = "kv/drone/github"
      values = {
          client_id = var.github_client_id
          client_secret = var.github_client_secret
      }
    },
    {
      path = "kv/drone/rpc"
      values = {
          secret = random_password.rpc.result
      }
    },
    {
      path = "kv/drone/pathschanged"
      values = {
          token = var.github_token
      }
    },
    {
      path = "kv/drone/vault"
      values = {
          role_id = vault_approle_auth_backend_role.drone-vault.role_id
          secret_id = vault_approle_auth_backend_role_secret_id.id.secret_id
      }
    },
    {
      path = "kv/tf-state"
      values = {
          conn_str = var.tf-state
      }
    }
  ]
}

resource "random_password" "rpc" {
  length = 32
  special = true
  override_special = "_%@"
}

variable "github_token" {
  default = ""
}
variable "github_client_id" {
  default = ""
}
variable "github_client_secret" {
  default = ""
}
variable "tf-state" {
  default = ""
}
