# Nacos with Podman Compose

这个目录把 Nacos 官方 `docker run` 示例等价转换成了 `podman-compose` 版本，默认以 `standalone + derby` 模式运行。

说明：

- 2026-03-15 实测 `docker.io/nacos/nacos-server:latest` 拉到的是 `Nacos Server 3.2.0-BETA`。
- 在当前镜像 + Java 17 组合下，需要通过 `JAVA_TOOL_OPTIONS=--add-opens=java.base/java.util=ALL-UNNAMED` 兼容启动；这个兼容项已经写进 compose 文件。

## 1. 准备环境变量

```bash
cd /home/jack711/code/infra-gitops/docker/nacos
cp .env.nacos.example .env.nacos
```

编辑 `.env.nacos`，至少替换下面 3 个值：

- `NACOS_AUTH_TOKEN`: 建议使用足够长的随机字符串
- `NACOS_AUTH_IDENTITY_KEY`
- `NACOS_AUTH_IDENTITY_VALUE`

## 2. 启动

如果你想沿用 `podman-compose` 命令：

```bash
cd /home/jack711/code/infra-gitops/docker/nacos
podman-compose up -d
```

如果你的系统更推荐 Podman 原生 Compose 插件，也可以直接用：

```bash
cd /home/jack711/code/infra-gitops/docker/nacos
podman compose -f podman-compose.yaml up -d
```

## 3. 查看状态

```bash
podman ps --filter name=nacos-standalone-derby
podman logs -f nacos-standalone-derby
curl -i http://127.0.0.1:8080/v3/console/health/readiness
```

## 4. 访问地址和端口

- `http://127.0.0.1:8080/index.html`: Nacos Console
- `http://127.0.0.1:8080/v3/console/health/readiness`: 实测可用的健康检查地址
- `8080`: 保持与官方示例一致的 Web 访问端口
- `8848`: Nacos HTTP/OpenAPI 端口
- `9848`: Nacos gRPC 端口

## 5. 停止和清理

```bash
cd /home/jack711/code/infra-gitops/docker/nacos
podman-compose down
```

如果要连同本地持久化数据一起清掉，再额外删除当前目录下的 `data/` 和 `logs/`。

## 6. 说明

- `./data` 和 `./logs` 已挂载到容器里，重启后数据和日志会保留。
- 卷挂载后缀使用了 `:Z`，这是为了兼容开启 SELinux 的 Podman 主机。
- 这里保持官方示例中的 `latest` 镜像标签；如果你要生产使用，建议改成明确版本号。
