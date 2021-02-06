#!/bin/sh

docker run --rm -ti -v /tmp:/tmp \
  psono/psono-server:latest python3 \
  ./psono/manage.py generateserverkeys | gsed -E "s/^(.+): '(.+)'/\L\1=\"\2\"/g" > /tmp/psono.tfvars

terraform apply -auto-approve -var-file=/tmp/psono.tfvars
# rm /tmp/psono.tfvars