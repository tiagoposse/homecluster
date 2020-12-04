
install()
{
  helm install $1 `yq r $1/details.yml "chart"` -f $1/values.yml -n `yq r $1/details.yml "namespace" ${2:""}`
}

build()
{
  printf "drone repo enable $1\n"
  drone repo enable $1
  drone build create $1
}

build_and_wait()
{
  build $1
  result=`drone build ls $1 --limit=1 | grep Status | cut -d " " -f 2`

  while [ "$result" != "success" ] && [ "$result" != "failure" ] && [ "$result" != "killed" ]
  do
    sleep 1m
    printf "Not done yet.\n"
    result=`drone build ls $1 --limit=1 | grep Status | cut -d " " -f 2`
  done
}

base()
{
  # Ingress
  install ingress

  # Cert Manager
  install certmanager "--wait"
  kubectl apply -f certmanager/k8s/issuer.yml

  install registry

  # Install vault
  git clone git@github.com:tiagoposse/vault-agent.git
  VERSION=`cat vault-agent/VERSION`
  (cd vault-agent && docker build -t vault-agent:${VERSION} . --platform=arm64)
  docker image tag vault-agent:${VERSION} registry.192.168.178.48.nip.io:443/vault-agent:${VERSION}
  docker push registry.192.168.178.48.nip.io:443/vault-agent:${VERSION}

  kubectl apply -f vault/k8s/vault_pre.yml
  install vault
  kubectl apply -f vault/k8s/vault_post.yml
}

setup()
{
  install museum

  k apply -f drone/k8s/pvc.yml
  k apply -f drone/k8s/monorepo-placeholder
  install drone
  k apply -f drone/k8s/build-sa.yml
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

$1