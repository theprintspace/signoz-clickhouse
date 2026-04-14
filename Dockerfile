FROM clickhouse/clickhouse-server:25.5.6

USER root

RUN apt-get update \
 && apt-get install -y --no-install-recommends wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

ARG HQ_VERSION=v0.0.1
RUN set -eux; \
    arch="$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)"; \
    cd /tmp; \
    wget -O hq.tgz "https://github.com/SigNoz/signoz/releases/download/histogram-quantile%2F${HQ_VERSION}/histogram-quantile_linux_${arch}.tar.gz"; \
    tar -xzf hq.tgz; \
    mkdir -p /var/lib/clickhouse/user_scripts; \
    mv histogram-quantile /var/lib/clickhouse/user_scripts/histogramQuantile; \
    chmod +x /var/lib/clickhouse/user_scripts/histogramQuantile; \
    rm hq.tgz

COPY config.xml          /etc/clickhouse-server/config.xml
COPY users.xml           /etc/clickhouse-server/users.xml
COPY custom-function.xml /etc/clickhouse-server/custom-function.xml
COPY cluster.xml         /etc/clickhouse-server/config.d/cluster.xml

ENV CLICKHOUSE_SKIP_USER_SETUP=1

EXPOSE 9000 8123 9181 9363
