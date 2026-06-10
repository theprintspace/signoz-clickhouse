FROM clickhouse/clickhouse-server:25.5.6

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# histogramQuantile UDF. Install OUTSIDE /var/lib/clickhouse: Railway mounts a
# persistent volume there at runtime, which shadows anything baked into the
# image under that path. The registration XML (custom-function.xml) lives in
# /etc and survives, so a binary under /var/lib/clickhouse/user_scripts/ would
# leave you with a registered function whose executable "does not exist".
# user_scripts_path in config.xml points at this off-volume dir.
ARG HQ_VERSION=v0.0.1
RUN set -eux; \
    arch="$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)"; \
    cd /tmp; \
    wget -O hq.tgz "https://github.com/SigNoz/signoz/releases/download/histogram-quantile%2F${HQ_VERSION}/histogram-quantile_linux_${arch}.tar.gz"; \
    tar -xzf hq.tgz; \
    mkdir -p /opt/clickhouse-user-scripts; \
    mv histogram-quantile /opt/clickhouse-user-scripts/histogramQuantile; \
    chmod +x /opt/clickhouse-user-scripts/histogramQuantile; \
    rm hq.tgz

ARG CACHEBUST=2
COPY config.xml          /etc/clickhouse-server/config.xml
COPY users.xml           /etc/clickhouse-server/users.xml
COPY custom-function.xml /etc/clickhouse-server/custom-function.xml
COPY cluster.xml         /etc/clickhouse-server/config.d/cluster.xml


EXPOSE 9000 8123 9181 9363
