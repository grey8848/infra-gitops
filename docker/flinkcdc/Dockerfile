FROM flink:1.20.1

# 放 CDC 官方 runner jar
COPY ./flink-cdc-dist-3.5.0.jar /opt/flink/lib/

# （可选）放 SQL
COPY ./job.sql /opt/flink/sql/job.sql
