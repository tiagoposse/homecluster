
locals {
  release = {
    name       = "psono"
    repository = "https://charts.tiagoposse.com"
    chart      = "psono"
    version    = "0.2.0"
    namespace  = "psono"
    values = [
      file("values.yml")
    ]
  }

  policies = {
    psono = <<EOT
path "kv/data/psono/*" {
  capabilities = ["read"]
}
EOT
    psono-database = <<EOT
path "kv/data/psono/database" {
  capabilities = ["read"]
}
EOT
  }

  roles = [
    {
      name = "psono-server"
      namespaces = [local.release.namespace]
      sas = ["psono-server"]
      policies = ["psono"]
    },
    {
      name = "psono-database"
      namespaces = [local.release.namespace]
      sas = ["psono-database", "psono-backup"]
      policies = ["psono-database"]
    },
  ]

  secrets = [
    {
      path = "kv/psono/credentials"
      values = {
          secret_key = var.secret_key
          activation_link_secret = var.activation_link_secret
          db_secret = var.db_secret
          email_secret_salt = var.email_secret_salt
          private_key = var.private_key
          public_key = var.public_key
      }
    },
    {
      path = "kv/psono/database"
      values = {
          password = random_password.db.result
      }
    }
  ]
}

variable "secret_key" {
  default = ""

  sensitive = true
}
variable "activation_link_secret" {
  default = ""

  sensitive = true
}
variable "db_secret" {
  default = ""

  sensitive = true
}
variable "email_secret_salt" {
  default = ""

  sensitive = true
}
variable "private_key" {
  default = ""

  sensitive = true
}
variable "public_key" {
  default = ""

  sensitive = true
}

resource "random_password" "db" {
  length = 32
  special = true
  override_special = "_%@"
}

resource "random_password" "email" {
  length = 32
  special = true
  override_special = "_%@"
}