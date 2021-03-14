
apply="kubectl apply -f"

$apply cluster/*

helm upgrade -i helm-operator fluxcd/helm-operator -n flux --create-namespace -f helm-operator/values.yml
$apply ingress/release.yml

$apply $(tr '\n' ' ' < certmanager/.deploy)
$apply $(tr '\n' ' ' < registry/release.yml)
$apply $(tr '\n' ' ' < museum/release.yml)
$apply $(tr '\n' ' ' < smallstep/.deploy)
$apply $(tr '\n' ' ' < vault/.deploy)

while [ "$(kubectl get po -n vault | grep -E 'vault-\d' | grep 'Running' | wc -l | xargs)" != "3" ]
do
  echo "$(kubectl get po -n vault | grep -E 'vault-\d' | grep 'Running' | wc -l | xargs)"
  sleep 2
done

echo $(kubectl exec -ti -n vault vault-0 -- cat /tmp/vault-init.json) > vault-init.json

$apply $(tr '\n' ' ' < kscp/release.yml)
$apply $(tr '\n' ' ' < cicd/.deploy)