
argo-rollouts

```shell
helm.exe upgrade --install argo-rollouts  .\argo\argo-rollouts-2.39.5.tgz -f .\argo\argo-rollouts.yml -n fpg-cloud --kubeconfig .\kubeconfig.yml
# 1. 创建命名空间
kubectl create namespace argocd
helm upgrade --install argo-rollouts 
```
