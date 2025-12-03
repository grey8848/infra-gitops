#!/bin/bash
# 函数：生成 Chart.yaml
create_chart_yaml() {
    local app_name=$1
    local repo_url=$2
    local chart_name=$3
    local version=$4

    cat <<EOF > charts/$app_name/Chart.yaml
apiVersion: v2
name: wrapper-$app_name
description: Wrapper chart for $app_name infra
type: application
version: 0.1.0
appVersion: "1.0.0"
dependencies:
  - name: $chart_name
    version: "$version"
    repository: "$repo_url"
EOF

    # 创建空的 values.yaml 作为默认层
    touch charts/$app_name/values.yaml
    # 创建 .helmignore
    echo "charts/" > charts/$app_name/.helmignore
}
echo "📦 生成 Helm Charts 配置..."

# 配置 Kafka (Bitnami)
create_chart_yaml "kafka" "https://charts.bitnami.com/bitnami" "kafka" "26.4.0"

# 配置 Flink (Bitnami)
create_chart_yaml "flink" "https://charts.bitnami.com/bitnami" "flink" "1.18.0"

# 配置 MySQL (Bitnami)
create_chart_yaml "mysql" "https://charts.bitnami.com/bitnami" "mysql" "9.14.0"

echo "🌍 生成环境差异化配置..."

# --- DEV 环境配置示例 ---
cat <<EOF > environments/dev/kafka-values.yaml
# Dev Environment Kafka Overrides
kafka:
  replicaCount: 1
  persistence:
    size: 5Gi
EOF

cat <<EOF > environments/dev/flink-values.yaml
# Dev Environment Flink Overrides
flink:
  jobmanager:
    replicaCount: 1
  taskmanager:
    replicaCount: 1
EOF

cat <<EOF > environments/dev/mysql-values.yaml
# Dev Environment MySQL Overrides
mysql:
  primary:
    persistence:
      size: 5Gi
  architecture: standalone
EOF

# --- PROD 环境配置示例 ---
cat <<EOF > environments/prod/kafka-values.yaml
# Prod Environment Kafka Overrides (High Availability)
kafka:
  replicaCount: 3
  persistence:
    size: 50Gi
  metrics:
    jmx:
      enabled: true
EOF

cat <<EOF > environments/prod/flink-values.yaml
# Prod Environment Flink Overrides
flink:
  jobmanager:
    replicaCount: 2
    highAvailability:
      enabled: true
EOF

cat <<EOF > environments/prod/mysql-values.yaml
# Prod Environment MySQL Overrides
mysql:
  architecture: replication
  primary:
    persistence:
      size: 100Gi
EOF

# ==========================================
# 4. 生成 ArgoCD Application Manifests
# ==========================================

echo "🐙 生成 ArgoCD 引导文件..."
# 生成 ArgoCD Application 的函数
create_argocd_app() {
    local env=$1
    local app=$2
    
    cat <<EOF > bootstrap/argocd-apps/$env-$app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $env-$app
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: 'https://github.com/YOUR_USERNAME/$PROJECT_NAME.git' # TODO: 修改为你的 Git 地址
    targetRevision: HEAD
    path: charts/$app
    helm:
      valueFiles:
        - values.yaml
        - ../../environments/$env/$app-values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: $env-infra
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
}

# 为 Dev 和 Prod 生成应用定义
for env in dev prod; do
    for app in kafka flink mysql; do
        create_argocd_app $env $app
    done
done

# 生成一个 "App of Apps" (可选，用于一次性部署所有应用)
cat <<EOF > bootstrap/root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-infra-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/YOUR_USERNAME/$PROJECT_NAME.git' # TODO: 修改为你的 Git 地址
    targetRevision: HEAD
    path: bootstrap/argocd-apps
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# ==========================================
# 5. 完成提示
# ==========================================
echo ""
echo "✅ 项目结构初始化完成！位置: ./$PROJECT_NAME"
echo ""
echo "下一步操作："
echo "1. 进入目录: cd $PROJECT_NAME"
echo "2. 初始化 Git: git init && git add . && git commit -m 'Initial commit'"
echo "3. 修改 bootstrap/argocd-apps/*.yaml 中的 repoURL 为你真实的 Git 仓库地址。"
echo "4. 推送到远程仓库 (GitHub/GitLab)。"
echo "5. 在 K8s 集群中应用根引导文件: kubectl apply -f bootstrap/root-app.yaml"
echo ""
