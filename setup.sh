!/bin/sh

echo "Insert github client id"
read github_client_id

echo "Insert github client secret"
read github_secret

echo "Insert cloudflare api secret"
read cloudflare

mkdir -p .tmp

echo "cloudflare_api_key=$cloudflare\ncloudflare_api_email=tiagoposse@gmail.com" > .tmp/cloudflare

docker run -ti --rm -v `pwd`/.tmp:/tmp \
  -v `pwd`/.tmp:/etc/letsencrypt/live/ \
  certbot/dns-cloudflare:arm64v8-v1.11.0 \
  certonly --dns-cloudflare \
  --dns-cloudflare-credentials /tmp/cloudflare \
  --dns-cloudflare-propagation-seconds 60 \
  -n --agree-tos -m tiagoposse@gmail.com \
  -d `yq e '.cluster.ingress.domains | join(" -d ")' cluster_details.yml`

kubectl create secret tls tiagoposse-ingress -n `yq r registry/details.yml "namespace"` \
    --key=.tmp/tiagoposse.com/privkey.pem --cert=.tmp/tiagoposse.com/fullchain.pem

# install ingress
helm install ingress `yq e ".chart" ingress/details.yml` -f ingress/values.yml \
  -n `yq e ".namespace" registry/details.yml` --repo `yq e ".url" registry/details.yml` \
  --create-namespace

# install registry
helm install registry `yq e ".chart" registry/details.yml` -f registry/values.yml \
  -n `yq e ".namespace" registry/details.yml` --repo `yq e ".url" registry/details.yml` \
  --create-namespace

# install vault
helm install vault `yq e ".chart" vault/details.yml` -f vault/values.yml \
  -n `yq e ".namespace" vault/details.yml` --create-namespace

git clone https://github.com/tiagoposse/custom-charts.git .tmp/custom-charts
git clone https://github.com/tiagoposse/cluster-droid.git .tmp/cluster-droid
git clone https://github.com/tiagoposse/drone-monorepo.git .tmp/drone-monorepo
docker build -t cluster-droid .tmp/helper-images/cluster-droid

VERSION=$(cat .tmp/cluster-droid/VERSION)
docker buildx build -t cluster-droid:$VERSION ./cluster-droid \
  --platform linux/arm64 \
  --build-arg=VAULT_VERSION=1.6.1 \
  --build-arg=HELM_VERSION=3.4.2 \
  --build-arg=KUBECTL_VERSION=1.18.10

docker tag cluster-droid:$VERSION registry.tiagoposse.com/cluster-droid:$VERSION
docker push registry.tiagoposse.com/cluster-droid:$VERSION

kubectl apply -f vault/setup-pod.yml

kubectl wait --timeout=180s --for=condition=Completed -n vault vault-setup

cp $KUBECONFIG .tmp/kubeconf
echo """
VAULT_TOKEN=/tmp/token
VAULT_ADDR=https://vault.tiagoposse.com
KUBECONFIG=/tmp/kubeconf""" > .tmp/docker-env

docker run -ti --rm -v `pwd`/.tmp:/tmp -v `pwd`:/conf \
  -e github_client_id=$github_client_id -e github_secret=$github_secret \
  --env-file=.tmp/docker-env \
  cluster-droid -a upgrade -d /conf/drone/details.yml --hooks=only-pre

DRONE_NAMESPACE=`yq e ".namespace" drone/details.yml`
docker run -ti --rm -v `pwd`/.tmp:/tmp -v `pwd`:/conf \
  --env-file=.tmp/docker-env \
  cluster-droid -a upgrade -d /conf/drone-runner/details.yml --hooks=only-pre

# Install drone
helm install drone .tmp/custom-charts/drone -f drone/values.yml -n $DRONE_NAMESPACE

# Install drone-runner
helm install drone-runner .tmp/custom-charts/drone-runner-kube -f drone-runner/values.yml -n $DRONE_NAMESPACE

export VERSION=$(cat .tmp/drone-monorepo/code/VERSION)
docker buildx build -t drone-monorepo:$VERSION .tmp/drone-monorepo/code \
  --platform linux/arm64
docker tag drone-monorepo:$VERSION registry.tiagoposse.com/drone-monorepo:$VERSION
docker push registry.tiagoposse.com/drone-monorepo:$VERSION

helm install -n $DRONE_NAMESPACE drone-monorepo .tmp/drone-monorepo/chart -f drone-monorepo/values.yml

rm -rf .tmp
sleep 5

echo "Insert drone token, find it at drone.tiagoposse.com"
read drone_token

export DRONE_SERVER=https://drone.tiagoposse.com
export DRONE_TOKEN=$drone_token

# Initial run of homecluster
drone repo sync

echo "Enabling helper-images"
REPO="tiagoposse/helper-images"
drone repo enable $REPO
drone repo update --trusted --config .drone.jsonnet $REPO
drone build create $REPO

echo "## Enabling homecluster"
REPO="tiagoposse/homecluster"
drone repo enable $REPO
drone repo update $REPO --trusted --config .drone.jsonnet
drone build create $REPO
