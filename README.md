
Terraform scripts to deploy the components of my home cluster. The cluster includes:
- Vault as a secrets management system
- Drone.io as CI/CD
- Chartmuseum as helm repo
- Certmanager to get TLS certificates
- Autocert for in-cluster certificate management.

For the first start please run `setup-tf.sh`.

This repo depends on:
- [tiagoposse/helper-images](https://github.com/tiagoposse/helper-images.git)
- [tiagoposse/custom-charts](https://github.com/tiagoposse/custom-charts.git)
- [tiagoposse/autocert](https://github.com/tiagoposse/autocert.git)