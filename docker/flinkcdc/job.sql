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
        'hostname' = '{{ .Values.cdc.mysql.hostname }}',
        'port' = '{{ .Values.cdc.mysql.port }}',
        'username' = '{{ .Values.cdc.mysql.username }}',
        'password' = '{{ .Values.cdc.mysql.password }}',
        'database-name' = '{{ .Values.cdc.mysql.database }}',
        'table-name' = '{{ .Values.cdc.mysql.table }}'
      );
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
        'jdbc-url' = '{{ .Values.cdc.starrocks.jdbcUrl }}',
        'load-url' = '{{ .Values.cdc.starrocks.loadUrl }}',
        'database-name' = '{{ .Values.cdc.starrocks.database }}',
        'table-name' = '{{ .Values.cdc.starrocks.table }}',
        'username' = '{{ .Values.cdc.starrocks.username }}',
        'password' = '{{ .Values.cdc.starrocks.password }}'
);
INSERT INTO sr_ods_user SELECT * FROM mysql_user;