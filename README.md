## DRY (Don't Repeat Yourself):
charts/ 目录下的 Wrapper Chart 包含逻辑。如果 Kafka 升级版本，你只需要改 charts/kafka/Chart.yaml 这一个文件，Dev 和 Prod 都会自动升级。
## 配置隔离:
Dev 和 Prod 的区别仅仅在于 environments/ 目录下的 values 文件。你可以很清楚地看到生产环境和开发环境的资源差异。
## App-of-Apps 模式:
通过 root-app.yaml 管理 argocd-apps 目录。如果你想新增一个 Redis，只需要在 argocd-apps 里加一个文件，ArgoCD 会自动检测到并部署，无需手动操作 kubectl。
## Bitnami 依赖:
脚本默认使用了 Bitnami 的 Charts，这是目前业界最稳定、维护最频繁的基础设施 Helm 仓库。
## 目录结构详解

```
infra-gitops/
├── bootstrap/                  # ArgoCD 的引导区
│   ├── root-app.yaml           # "App of Apps" 入口，一键部署所有应用
│   └── argocd-apps/            # 每个应用的 ArgoCD 定义
│       ├── dev-kafka.yaml
│       ├── prod-kafka.yaml
│       ├── dev-mysql.yaml
│       └── ...
├── charts/                     # Helm Charts (代码/逻辑层)
│   ├── kafka/
│   │   ├── Chart.yaml          # 依赖 Bitnami Kafka
│   │   └── values.yaml         # 通用默认配置
│   ├── flink/
│   │   ...
│   └── mysql/
│       ...
└── environments/               # 环境参数 (配置层)
    ├── dev/
    │   ├── kafka-values.yaml   # 开发环境特有的轻量配置
    │   ├── flink-values.yaml
    │   └── mysql-values.yaml
    └── prod/
        ├── kafka-values.yaml   # 生产环境的高可用/大磁盘配置
        └── ...
# 在宿主机执行

# 1. 找到你的 registry 容器名
docker ps | grep registry

# 2. 将 registry 连接到 kind 网络（假设容器名是 local-registry）
docker network connect kind local-registry

# 3. 测试连通性
docker exec my-cluster-control-plane ping -c 2 local-registry
docker exec my-cluster-control-plane curl http://local-registry:5000/v2/_catalog
# 7. 测试拉取（使用 local-registry:5000）
docker exec my-cluster-control-plane crictl pull local-registry:5000/traefik:latest

```
# 创建临时pod进行网络测试包含crul
```
kubectl run netshoot \                                                                                                                                                                                                        49m 39s   dbt
--rm -it \
--image=local-registry:5000/nicolaka-netshoot \
--restart=Never \
-- bash

```
-- 手动创建job-mananger 这个步骤要确定 的是
❯ kubectl exec -it flink-cdc-7d78c44f85-k7rkl -n flink --  \
  /opt/flink/bin/flink run \
  -c org.apache.flink.cdc.cli.CliFrontend \
  /opt/flink/lib/flink-cdc-dist-3.5.0.jar \
  /opt/flink/pipeline.yaml
ERROR StatusLogger Reconfiguration failed: No configuration found for '2b71fc7e' at 'null' in 'null'
Fri Jan 02 10:53:33 UTC 2026 WARN: Establishing SSL connection without server's identity verification is not recommended. According to MySQL 5.5.45+, 5.6.26+ and 5.7.6+ requirements SSL connection must be established by default if explicit option isn't set. For compliance with existing applications not using SSL the verifyServerCertificate property is set to 'false'. You need either to explicitly disable SSL by setting useSSL=false, or set useSSL=true and provide truststore for server certificate verification.
Pipeline has been submitted to cluster.
Job ID: 1c43c01d0ead5a03cddab863397a8cd6
Job Description: MySQL to StarRocks Sync
```

```
CREATE TABLE `order` (
  `order_id` bigint NOT NULL COMMENT '订单ID',
  `user_id` bigint DEFAULT NULL COMMENT '用户ID',
  `order_amount` decimal(10,2) DEFAULT NULL COMMENT '订单金额',
  `order_status` varchar(50) DEFAULT NULL COMMENT '订单状态',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`order_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='订单表';

CREATE TABLE `user` (
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `user_name` varchar(255) DEFAULT NULL COMMENT '用户名',
  `gender` varchar(20) DEFAULT NULL COMMENT '性别',
  `status` varchar(50) DEFAULT NULL COMMENT '用户状态',
  `register_time` datetime DEFAULT NULL COMMENT '注册时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';


fedora
systemd-run --scope --user -p "Delegate=yes" \
  env KIND_EXPERIMENTAL_PROVIDER=podman \
  kind create cluster --name fpg --config kind-config.yaml