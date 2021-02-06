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
