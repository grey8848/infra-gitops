```sql
-- 用 Flink SQL Job
-- MySQL CDC Source
CREATE TABLE mysql_user (
  user_id BIGINT,
  user_name STRING,
  gender STRING,
  status STRING,
  register_time TIMESTAMP(3),
  update_time TIMESTAMP(3),
  PRIMARY KEY (user_id) NOT ENFORCED
) WITH (
  'connector' = 'mysql-cdc',
  'hostname' = 'mysql',
  'port' = '3306',
  'username' = 'root',
  'password' = 'xxx',
  'database-name' = 'app',
  'table-name' = 'user'
);
-- 
CREATE TABLE sr_ods_user (
  user_id BIGINT,
  user_name STRING,
  gender STRING,
  status STRING,
  register_time TIMESTAMP(3),
  update_time TIMESTAMP(3),
  PRIMARY KEY (user_id) NOT ENFORCED
) WITH (
  'connector' = 'starrocks',
  'jdbc-url' = 'jdbc:mysql://starrocks:9030',
  'load-url' = 'starrocks:8030',
  'database-name' = 'analytics',
  'table-name' = 'ods_user_cdc',
  'username' = 'root',
  'password' = ''
);
-- 启动同步脚本
insert into sr_ods_user
select * from mysql_user;
```

 完成的工作

  1. 新增 CDC 配置 (charts/flink-jobs/values.yaml)

  - 添加了 cdc 配置块，包含：
    - enabled: false - 默认禁用，需要时手动启用
    - MySQL 连接参数（主机、端口、认证、数据库/表）
    - StarRocks 连接参数（JDBC URL、Load URL、数据库/表）
    - 作业名称和并行度配置

  2. 创建 FlinkDeployment 模板 (charts/flink-jobs/templates/flink-cdc.yaml)

  - 基于现有 flink-demo.yaml 结构，使用 sqlScript 字段嵌入 Flink SQL 作业
  - 完整的 MySQL CDC → StarRocks 同步 SQL 脚本，参数从 values.yaml 注入
  - 条件渲染：仅当 cdc.enabled=true 时生成资源
  - 资源分配复用现有的 TaskManager 配置

  3. SQL 脚本内容

  - 源表：mysql_user (MySQL CDC connector)
  - 目标表：sr_ods_user (StarRocks connector)
  - 表结构参考 skill.md 中的定义
  - 包含完整的 WITH 配置，参数通过模板变量动态注入

  使用方式

  1. 启用 CDC 作业：
  # values.yaml 中设置
  cdc:
    enabled: true
  2. 自定义连接参数：
  cdc:
    mysql:
      hostname: your-mysql-host
      password: your-password
    starrocks:
      jdbcUrl: jdbc:mysql://your-starrocks:9030
      loadUrl: your-starrocks:8030
  3. 部署：
  helm upgrade --install flink-jobs ./charts/flink-jobs --set cdc.enabled=true

  注意事项

  1. 镜像要求：当前配置使用 local-registry:5000/flink-orgin:1.20.1，需确保该镜像包含：
    - MySQL CDC connector
    - StarRocks connector
  2. 集群依赖：
    - Flink Kubernetes Operator 需支持 sqlScript 字段
    - flink ServiceAccount 必须存在
  3. 安全建议：
    - 生产环境避免在 values.yaml 中硬编码密码
    - 考虑使用 Kubernetes Secrets 管理认证信息

  模板已通过 helm template 测试，SQL 脚本中的参数替换正常。用户可根据实际环境调整连接配置。