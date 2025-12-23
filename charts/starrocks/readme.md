```sql
-- basic table 
CREATE TABLE user_log (
  dt DATE,
  user_id BIGINT,
  action VARCHAR(20),
  score INT
)
DUPLICATE KEY(dt, user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);

INSERT INTO user_log VALUES
('2025-01-01', 1, 'click', 10),
('2025-01-01', 2, 'view', 5),
('2025-01-02', 1, 'buy', 100);



SELECT dt, SUM(score)
FROM user_log
GROUP BY dt;


EXPLAIN ANALYZE
SELECT dt, SUM(score)
FROM user_log
GROUP BY dt;


CREATE TABLE dwd_user_action (
  dt DATE,
  user_id BIGINT,
  action VARCHAR(20),
  score INT
)
DUPLICATE KEY(dt, user_id, action)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);
INSERT INTO dwd_user_action
SELECT *
FROM user_log;


-- show fe replication table
ADMIN SHOW FRONTEND CONFIG LIKE '%replication%';

```

1️⃣ 表模型（比 SQL 技巧重要 10 倍）

DUPLICATE / AGGREGATE / UNIQUE

什么时候用 AGGREGATE

什么时候“反而不能去重”

2️⃣ 分桶 & 分区（性能的骨架）

DATE 分区 vs 不分区

BUCKETS 怎么估

单 BE 和多 BE 的差别

3️⃣ 执行计划（别信直觉）

EXPLAIN

EXPLAIN ANALYZE

ScanNode / AggregateNode

4️⃣ FE / BE 各自负责什么

FE 不存数据

BE 不管 SQL 语义

Operator 只是“管家”


五、一个很重要的学习姿态（送你一句老话）

不要追新特性，先理解为什么 OLAP 一定要“列存 + 向量化 + 分布式”。

等你把这些吃透了，再去看：

物化视图

实时导入（Kafka）

多副本 & 高可用

冷热数据分层

系统跑着、心态稳了、方向也对。

下一步如果你愿意，我可以直接给你一套：

学习用 StarRocks 数仓分层 + 完整 DDL
或 从 MySQL 业务表 → ODS → DWD 的真实迁移演练
或 只讲 StarRocks 和 ClickHouse 的“哲学差异”


```sql
-- ods层
CREATE TABLE ods_user_action_log (
  dt DATE COMMENT '业务日期',
  user_id BIGINT COMMENT '用户ID',
  action VARCHAR(20) COMMENT '行为类型',
  event_time DATETIME COMMENT '事件发生时间',
  score INT COMMENT '行为分值'
)
DUPLICATE KEY(dt, user_id, action, event_time)
PARTITION BY RANGE(dt) (
  PARTITION p20250101 VALUES LESS THAN ('2025-01-02'),
  PARTITION p20250102 VALUES LESS THAN ('2025-01-03')
)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);
```

```sql
-- dwd 事实层
CREATE TABLE dwd_user_action (
  dt DATE COMMENT '业务日期',
  user_id BIGINT COMMENT '用户ID',
  action VARCHAR(20) COMMENT '行为类型',
  event_time DATETIME COMMENT '事件时间',
	score INT COMMENT '标准化分值'
)
DUPLICATE KEY(dt, user_id, action, event_time)
PARTITION BY RANGE(dt) (
  PARTITION p20250101 VALUES LESS THAN ('2025-01-02'),
  PARTITION p20250102 VALUES LESS THAN ('2025-01-03')
)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);


-- dwd => ods
INSERT INTO dwd.dwd_user_action
SELECT
  dt,
  user_id,
  action,
  score,
  event_time
FROM ods.ods_user_action_log;

-- dim
CREATE TABLE dim_user (
  user_id BIGINT COMMENT '用户ID',
  user_name VARCHAR(50),
  user_type VARCHAR(20),
  register_date DATE
)
UNIQUE KEY(user_id)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);

-- dwd => dws
CREATE TABLE dws_user_action_day (
  dt DATE COMMENT '日期',
  user_id BIGINT COMMENT '用户ID',
  action_cnt BIGINT SUM COMMENT '行为次数',
  total_score BIGINT SUM COMMENT '行为总分'
)
AGGREGATE KEY(dt, user_id)
PARTITION BY RANGE(dt) (
  PARTITION p20250101 VALUES LESS THAN ('2025-01-02'),
  PARTITION p20250102 VALUES LESS THAN ('2025-01-03')
)
DISTRIBUTED BY HASH(user_id) BUCKETS 3
PROPERTIES (
  "replication_num" = "1"
);

INSERT INTO dws.dws_user_action_day
SELECT
  dt,
  user_id,
  COUNT(*) AS action_cnt,
  SUM(score) AS total_score
FROM dwd.dwd_user_action
GROUP BY dt, user_id;

-- dws => ads
CREATE TABLE ads_user_day_summary (
  dt DATE COMMENT '日期',
  active_user_cnt BIGINT COMMENT '活跃用户数',
  total_score BIGINT COMMENT '总分'
)
DUPLICATE KEY(dt)
PARTITION BY RANGE(dt) (
  PARTITION p20250101 VALUES LESS THAN ('2025-01-02'),
  PARTITION p20250102 VALUES LESS THAN ('2025-01-03')
)
DISTRIBUTED BY HASH(dt) BUCKETS 1
PROPERTIES (
  "replication_num" = "1"
);

INSERT INTO ads.ads_user_day_summary
SELECT
  dt,
  COUNT(DISTINCT user_id),
  SUM(total_score)
FROM dws.dws_user_action_day
GROUP BY dt;

```
这是我理解的数仓的设计结构


