FROM flink:1.20.1

RUN mkdir -p /opt/flink/usrlib
# 放 CDC 官方 runner jar
COPY ./flink-cdc-dist-3.5.0.jar /opt/flink/usrlib/

COPY ./flink-cdc-common-3.5.0.jar /opt/flink/lib/
COPY ./flink-cdc-pipeline-connector-mysql-3.5.0.jar /opt/flink/lib/
COPY ./flink-cdc-pipeline-connector-starrocks-3.5.0.jar /opt/flink/lib/
COPY ./mysql-connector-j-8.0.33.jar /opt/flink/lib/

