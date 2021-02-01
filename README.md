
Values and definitions 


# details.yml

```
namespace: namespace for release
release: release name
chart: chart ref without (/)
url: url of the chart
valuesFile: location of custom values.yml for this release
version: chart version
hooks: # {}
  preInstall: # []
    - resource: vault/k8s/auth-setup.yml
      operation: apply
  postInstall: []
    - resource: vault/resources/setup_certificate.sh
      operation: execute
vault: location of vault file to process (used by vault-droid)
```