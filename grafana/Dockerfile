ARG GRAFANA_VERSION=13.1.7
ARG PGWATCH_VERSION=6.0.0

# Stage 1: fetch the pgwatch v13 Postgres-sink dashboards for the matching release tag
FROM alpine:3.20 AS dashboards
ARG PGWATCH_VERSION
RUN apk add --no-cache curl tar \
 && mkdir -p /out \
 && curl -fsSL "https://codeload.github.com/cybertec-postgresql/pgwatch/tar.gz/refs/tags/v${PGWATCH_VERSION}" \
    | tar -xz -C /out --strip-components=4 "pgwatch-${PGWATCH_VERSION}/grafana/postgres/v13"

# Stage 2: Grafana 13 (pgwatch v6 dashboards use the v13 schema + dashboardNewLayouts)
FROM grafana/grafana:${GRAFANA_VERSION}
USER root
RUN grafana cli plugins install marcusolsson-treemap-panel
USER 472
COPY --from=dashboards --chown=472:0 /out /var/lib/grafana/dashboards/pgwatch
COPY --chown=472:0 --chmod=0755 entrypoint.sh /entrypoint.sh

ENV GF_FEATURE_TOGGLES_ENABLE=dashboardNewLayouts \
    GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/pgwatch/1-global-db-overview.json

EXPOSE 3000
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
