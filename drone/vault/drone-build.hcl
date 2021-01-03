
path "sys/policy/*" {
  capabilities = ["create", "update"]
}

path "sys/policies/acl/*" {
  capabilities = ["create", "update"]
}

path "auth/kubernetes/role/*" {
  capabilities = ["create", "update"]
}

path "kv/*" {
  capabilities = ["create", "update", "list", "read"]
}