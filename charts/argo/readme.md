
argo-rollouts

```shell
helm upgrade --install argo-rollouts  .\argo\argo-rollouts-2.39.5.tgz -f .\argo\argo-rollouts.yml -n fpg-cloud --kubeconfig .\kubeconfig.yml
# 1. 创建命名空间
kubectl create namespace argocd
helm upgrade --install argo-rollouts 

helm upgrade --install argocd ./argo-cd-7.8.19.tgz -f ./argo-values.yaml --namespace argocd --create-namespace --history-max 2
## 创建argo ingress 基于trafik


```
