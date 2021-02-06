
data "cloudflare_zones" "tposse" {
  filter {
    name = "tiagoposse.com"
  }
}

# Create a record
resource "cloudflare_record" "records" {
  for_each = toset(local.records)

  zone_id = data.cloudflare_zones.tposse.zones[0].id
  name    = each.value
  value   = local.external_ip
  type    = "A"
}

variable "cloudflare_email" {}
variable "cloudflare_api_key" {}

locals {
  external_ip = chomp(data.http.my_public_ip.body)
  records = [
    "www",
    "drone",
    "vault",
    "registry",
    "dashboard",
    "media",
    "charts",
    "psono",
    "plex"
  ]
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_token = var.cloudflare_api_key
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "2.18.0"
    }
  }

  backend "pg" {}
}