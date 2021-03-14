#!/bin/sh

NAMESPACE=$(cat ../terraform.tfvars.json | jq -r ".release.namespace")
THRESHOLD=$(cat ../terraform.tfvars.json | jq -r ".config.threshold")
SHARES=$(cat ../terraform.tfvars.json | jq -r ".config.shares")
REPLICAS=$(cat ../values.yml | grep "replicas:" | awk '{print $2}')

kubectl exec -ti -n $NAMESPACE vault-0 -- vault operator init -format=json >> vault-init.json

for r in $(seq 0 $((REPLICAS-1)))
do
  for k in $(seq 1 $THRESHOLD)
  do
    kubectl exec -ti -n $NAMESPACE vault-$r -- vault operator unseal $(cat vault-init.json | jq -r ".unseal_keys_b64[$k]")
  done
  
  sleep 10
done

vault secrets enable -version=2 -path=kv kv
vault auth enable kubernetes
vault write auth/kubernetes/config \
    token_reviewer_jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    kubernetes_host=https://10.24.112.1 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt