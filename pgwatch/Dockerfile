# pgwatch collector + admin WebUI for Aiven Application service.
# Config (sources/metrics) and metrics sink both live in an Aiven for PostgreSQL service,
# injected via the service integration as DATABASE_URL.
ARG PGWATCH_VERSION=6.0.0
FROM cybertecpostgresql/pgwatch:${PGWATCH_VERSION}

COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# WebUI / REST API (the Aiven app "port" must be 8080)
EXPOSE 8080
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
