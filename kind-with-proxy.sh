#!/usr/bin/env bash

set -e

CLUSTER_NAME="my-cluster"
HTTP_PROXY="http://host.docker.internal:10809"
HTTPS_PROXY="http://host.docker.internal:10809"

echo "===> Injecting proxy config into kind node..."

NODE="${CLUSTER_NAME}-control-plane"
echo "$NODE"

docker exec "$NODE" bash -c "
  mkdir -p /etc/systemd/system/containerd.service.d
  cat <<EOP >/etc/systemd/system/containerd.service.d/http-proxy.conf
[Service]
Environment=\"HTTP_PROXY=${HTTP_PROXY}\"
Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"
Environment=\"NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,cluster.local\"
EOP
"

docker exec "$NODE" bash -c "
  mkdir -p /etc/systemd/system/kubelet.service.d
  cat <<EOP >/etc/systemd/system/kubelet.service.d/10-proxy.conf
[Service]
Environment=\"HTTP_PROXY=${HTTP_PROXY}\"
Environment=\"HTTPS_PROXY=${HTTPS_PROXY}\"
Environment=\"NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,cluster.local\"
EOP
"

docker exec "$NODE" bash -c "
cat <<EOP >/etc/environment
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}
http_proxy=${HTTP_PROXY}
https_proxy=${HTTPS_PROXY}
NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,cluster.local
EOP
"
docker exec $NODE sh -c "cat <<'EOF' >/etc/profile.d/proxy.sh
export HTTP_PROXY=http://host.docker.internal:10809
export HTTPS_PROXY=http://host.docker.internal:10809
export http_proxy=http://host.docker.internal:10809
export https_proxy=http://host.docker.internal:10809
export NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,cluster.local
EOF"

docker exec $NODE sh -c "cat <<'EOF' >>/root/.bashrc
export HTTP_PROXY=http://host.docker.internal:10809
export HTTPS_PROXY=http://host.docker.internal:10809
export http_proxy=http://host.docker.internal:10809
export https_proxy=http://host.docker.internal:10809
export NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,cluster.local
EOF"

docker exec "$NODE" bash -c "
  systemctl daemon-reload
  systemctl restart containerd
  systemctl restart kubelet
  . /etc/profile.d/proxy.sh
  source /root/.bashrc
  systemctl show containerd | grep -i proxy
  echo "$http_proxy"
"
docker exec my-cluster-control-plane 'cat > /tmp/registry.patch <<EOT
[plugins."io.containerd.grpc.v1.cri".registry]
  config_path = "/etc/containerd/certs.d"
EOT
cat /tmp/registry.patch >> /etc/containerd/config.toml'
docker exec my-cluster-control-plane mkdir -p /etc/containerd/certs.d/localhost:5031
docker exec my-cluster-control-plane sh -c 'cat > /etc/containerd/certs.d/localhost:5031/hosts.toml << "EOF"
server = "http://local-registry:5000"

[host."http://local-registry:5000"]
  capabilities = ["pull", "resolve", "push"]
  skip_verify = true
EOF'

echo
echo "===> Proxy injection completed for cluster '$CLUSTER_NAME'."
echo "     You may now use ctr/kubectl normally through the proxy."
echo

