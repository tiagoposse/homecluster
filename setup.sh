
install()
{
  echo """helm install $1 `yq r $1/details.yml "chart"` -f $1/values.yml -n `yq r $1/details.yml "namespace" ${2:""}`"""
  helm install $1 `yq r $1/details.yml "chart"` -f $1/values.yml -n `yq r $1/details.yml "namespace" ${2:""}` --repo `yq r $1/details.yml "url"`
}

build()
{
  printf "drone repo enable $1\n"
  drone repo enable $1
  drone repo update --config ${2:".drone.jsonnet"} $1
  drone build create $1
}

build_and_wait()
{
  build $1 $2
  result=`drone build ls $1 --limit=1 | grep Status | cut -d " " -f 2`

  while [ "$result" != "success" ] && [ "$result" != "failure" ] && [ "$result" != "killed" ]
  do
    sleep 1m
    printf "Not done yet.\n"
    result=`drone build ls $1 --limit=1 | grep Status | cut -d " " -f 2`
  done
}

repos()
{
  drone repo sync

  DEFAULT_REPO=`yq r projects.yml "repository"`

  for project in `yq r projects.yml "repos.*" -p p`
  do
    name=`echo ${project} | cut -d "." -f 2`
    repo=`yq r projects.yml "${project}.repository"`
    repo="${repo:-$DEFAULT_REPO}"

    if [ ! -z "`yq r projects.yml \"${project}.wait\"`" ]
    then
      build_and_wait ${repo}/${name}
    else
      build ${repo}/${name}
    fi
    
    echo "done"
  done
}

echo "Insert github client id"
read github_client_id

echo "Insert github client secret"
read github_secret

install ingress
install registry

git clone https://github.com/drone/drone-kaniko.git /tmp/kaniko
(cd /tmp/kaniko && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 GO111MODULE=on go build -v -a -tags netgo -o release/linux/arm64/kaniko-docker ./cmd/kaniko-docker)
(cd /tmp/kaniko && docker build -t drone-kaniko . -f docker/docker/Dockerfile.linux.arm64)
docker tag drone-kaniko registry.192.168.178.48.nip.io/drone-kaniko
docker push registry.192.168.178.48.nip.io/drone-kaniko

helm repo add drone https://charts.drone.io
helm repo update
RPC_SECRET=`openssl rand -base64 32`
helm install drone drone/drone -f drone/pre-values.yml -n drone --create-namespace --set env.DRONE_GITHUB_CLIENT_ID=$github_client_id,env.DRONE_GITHUB_CLIENT_SECRET=$github_secret,env.DRONE_RPC_SECRET=$RPC_SECRET
helm install drone-runner drone/drone-runner-kube -f drone-kube-runner/pre-values.yml -n builds --create-namespace --set env.DRONE_RPC_SECRET=$RPC_SECRET

printf "Insert drone token"
read drone_token
export DRONE_SERVER=https://drone.tiagoposse.com
export DRONE_TOKEN=$drone_token

# Initial run of homecluster
drone repo sync
drone orgsecret add tiagoposse drone_token $RPC_SECRET
build_and_wait tiagoposse/helper-images

build_and_wait tiagoposse/homecluster .init.jsonnet

build tiagoposse/drone-monorepo
# Re install
helm uninstall -n drone drone
helm uninstall -n builds drone-runner

install drone-kube-runner
install drone "--wait"
