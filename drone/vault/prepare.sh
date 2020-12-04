vault policy write drone-pol drone.hcl

vault write auth/kubernetes/role/drone bound_service_account_names=default bound_service_account_namespaces=drone policies=drone-pol ttl=1h

vault policy write drone-runner-pol drone-runner.hcl

vault write auth/kubernetes/role/drone-runner bound_service_account_names=drone-runner-drone-runner-kube bound_service_account_namespaces=builds policies=drone-pol ttl=1h


vault policy write drone-monorepo-pol drone-monorepo.hcl

vault write auth/kubernetes/role/drone-monorepo bound_service_account_names=drone-monorepo bound_service_account_namespaces=drone policies=drone-monorepo-pol ttl=1h


vault policy write drone-vault-pol drone-vault.hcl

vault write auth/kubernetes/role/drone-vault bound_service_account_names=drone-vault-sa bound_service_account_namespaces=drone policies=drone-vault-pol ttl=1h