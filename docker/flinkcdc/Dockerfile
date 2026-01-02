FROM flink:1.20.1

# 放 CDC 官方 runner jar
COPY ./flink-cdc-dist-3.5.0.jar /opt/flink/lib/

COPY ./flink-cdc-runtime-3.5.0.jar /opt/flink/lib/
COPY ./flink-cdc-common-3.5.0.jar /opt/flink/lib/
COPY ./flink-cdc-pipeline-connector-mysql-3.5.0.jar /opt/flink/lib/
COPY ./flink-cdc-pipeline-connector-starrocks-3.5.0.jar /opt/flink/lib/
COPY ./mysql-connector-j-8.0.33.jar /opt/flink/lib/

# 创建启动脚本
RUN echo '#!/bin/bash\n\
java -cp /opt/flink/lib/*:/opt/flink/lib/flink-dist-*.jar \\\n\
  org.apache.flink.cdc.composer.PipelineExecution \\\n\
  "$@"' > /opt/flink/bin/cdc-pipeline.sh && \
  chmod +x /opt/flink/bin/cdc-pipeline.sh