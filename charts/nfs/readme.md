helm upgrade --install nfs-provisioner .\nfs\nfs-subdir-external-provisioner-4.0.18.tgz \
  -f .\nfs\nfs.yaml \
  --kubeconfig .\kubeconfig.yml

helm uninstall nfs-provisioner --kubeconfig .\kubeconfig.yml