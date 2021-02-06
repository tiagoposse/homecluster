
form() {
  echo "Terraforming $1"
  TF="terraform -chdir=$1"
  $TF init -backend-config="conn_str=$CONN_STR" -input=false
  $TF workspace new $1
  $TF plan $2
  $TF apply -auto-approve $2
}

chart() {
  NAME=$1
  FOLDER=$2
  helm package $FOLDER -d $FOLDER
  curl -X POST --data-binary @$FOLDER/$NAME-`cat $FOLDER/Chart.yaml | grep "version:" | cut -d " " -f 2`.tgz -k https://charts.tiagoposse.com/api/charts
}

clone () {
  git clone https://github.com/tiagoposse/$1.git .tmp/$1
}

images_and_charts() {
  DOCKER="docker buildx build --platform=linux/arm64 --push -t registry.tiagoposse.com"
  $DOCKER/vault-agent:0.8.0 --build-arg="APP_VERSION=0.8.0" .tmp/helper-images/vault-agent
  $DOCKER/kaniko-arm:1.3.0 --build-arg="VERSION=1.3.0" .tmp/helper-images/kaniko-arm
  $DOCKER/autocert-controller:0.1.1 -f .tmp/autocert/controller/Dockerfile .tmp/autocert
  $DOCKER/terraform:$(cat .tmp/helper-images/terraform/VERSION) .tmp/helper-images/terraform

  chart drone .tmp/custom-charts/drone
  chart drone-runner-kube .tmp/custom-charts/drone-runner-kube
  chart drone-pathschanged .tmp/custom-charts/drone-pathschanged
}

setup_pg_db() {
  ssh tposse@192.168.178.48 docker run -ti --rm --name=tf-state -d -p 5432:5432 \
    -v /home/tposse/pgdata:/var/lib/postgresql/data \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -e POSTGRES_PASSWORD=$PSQL_PASSWORD \
    -e POSTGRES_USER=$PSQL_USER \
    -e POSTGRES_DB=$PSQL_DB \
    postgres

  sleep 15
}

if [ ! -z "$1" ]
then
  export $(cat $1 | xargs)
else
  echo """You need a file as such as the first argument:
  clouflare_email=
  cloudflare_api_key=
  github_token=
  github_client_id=
  github_secret=
  """
  exit 1
fi

# mkdir -p .tmp
# clone helper-images; clone autocert; clone custom-charts; clone drone-monorepo

export KUBE_CONFIG_PATH=$KUBECONFIG
export PSQL_HOST="192.168.178.48"
export PSQL_PASSWORD=`env LC_CTYPE=C tr -dc 'a-z0-9' < /dev/urandom | head -c24`
export PSQL_USER="postgres"
export PSQL_DB="terraform"
export CONN_STR="postgres://$PSQL_USER:$PSQL_PASSWORD@$PSQL_HOST/$PSQL_DB?sslmode=disable"
echo "PSQL: $PSQL_PASSWORD"
# setup_pg_db

# echo "terraform init -backend-config=\"conn_str=$CONN_STR\""
# (cd cluster && terraform init -backend-config="conn_str=$CONN_STR")

# form cluster
# form dns "-var=cloudflare_email=$cloudflare_email -var=cloudflare_api_key=$cloudflare_api_key" && sleep 90
# form ingress
# form certmanager
# form registry
# form museum

# images_and_charts

# form smallstep
# form secrets
# while [ "$(kubectl get po -n vault | grep -E 'vault-\d' | grep 'Running' | wc -l | xargs)" != "3" ]
# do
#   echo "$(kubectl get po -n vault | grep -E 'vault-\d' | grep 'Running' | wc -l | xargs)"
#   sleep 2
# done
# (cd secrets/setup && ./init-vault.sh)
# export VAULT_TOKEN=$(cat secrets/setup/vault-init.json | jq -r ".root_token")
# (cd secrets && form setup -var-file="../terraform.tfvars.json")

form pipeline "-var=github_token=$github_token -var=github_client_id=$github_client_id -var=github_secret=$github_client_secret -var=tf-state=$CONN_STR"

# rm -rf .tmp