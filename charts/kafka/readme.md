  新增的监控指标

  1. Broker 核心指标

  - 消息流入/流出速率（MessagesInPerSec, BytesInPerSec, BytesOutPerSec）
  - 按 Topic 维度的流量统计

  2. 网络请求指标

  - 各类请求的 QPS（Produce, Fetch, Metadata 等）
  - 请求处理时间（平均值和百分位数）
  - 请求队列大小

  3. 分区相关指标

  - 分区大小
  - 未充分复制的分区（Under Replicated Partitions）

  4. Controller 指标

  - 活跃 Controller 数量（集群中应该只有 1 个）
  - 离线分区数量
  - Leader 选举次数
  - 非正常 Leader 选举次数

  5. 副本管理指标

  - 未充分复制的分区数
  - 分区总数和 Leader 分区数
  - ISR 收缩/扩展次数
  - 副本最大延迟

  6. 性能指标

  - Request Handler 空闲率
  - Purgatory 队列大小（Produce/Fetch）
  - 日志刷新次数和时间
  - 网络处理器空闲率

  7. ZooKeeper 连接指标

  - ZK 断开连接次数
  - ZK 会话过期次数

  8. Consumer Lag 指标

  - Consumer Group 消费延迟

  在 Grafana 中使用这些指标

  你可以在 Grafana（10.244.0.17）中创建 Dashboard，使用以下 PromQL 查询：

  # Broker 吞吐量
  rate(kafka_server_brokertopicmetrics_messagesin_total[5m])
  rate(kafka_server_brokertopicmetrics_bytesin_total[5m])

  # 请求处理延迟
  kafka_network_requestmetrics_totaltimems_mean{request="Produce"}

  # 未充分复制的分区（重要告警指标）
  kafka_server_replica_manager_under_replicated_partitions

  # Offline 分区（重要告警指标）
  kafka_controller_offline_partitions_count

  # 按 Topic 的流量
  rate(kafka_server_brokertopicmetrics_BytesInPerSec_total{topic="your-topic"}[5m])