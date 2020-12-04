vault policy write dyndns-pol dyndns.hcl

vault write auth/kubernetes/role/dyndns bound_service_account_names=dyndns-sa bound_service_account_namespaces=tools policies=dyndns-pol ttl=1h