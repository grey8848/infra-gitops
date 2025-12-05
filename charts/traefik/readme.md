```shell
cd charts/traefix
helm upgrade --install traefik ./traefik-37.4.0.tgz -f ./values.yml --namespace traefik --create-namespace --wait
ctr -n k8s.io images pull docker.io/library/traefik:v3.6.2
```