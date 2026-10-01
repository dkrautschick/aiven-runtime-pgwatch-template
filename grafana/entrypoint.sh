#!/bin/sh
# Provisions the pgwatch dashboards + a Postgres datasource from the Aiven PG integration.
set -eu

: "${DATABASE_URL:?DATABASE_URL missing - add a pg service integration with env_key DATABASE_URL}"
: "${GF_SECURITY_ADMIN_PASSWORD:?GF_SECURITY_ADMIN_PASSWORD missing - set it as a secret env var}"

# postgres://user:pass@host:port/db?sslmode=require
rest="${DATABASE_URL#*://}"
creds="${rest%%@*}";  hostpart="${rest#*@}"
PGUSER="${creds%%:*}"; PGPASSWORD="${creds#*:}"
PGHOSTPORT="${hostpart%%/*}"
dbq="${hostpart#*/}";  PGDATABASE="${dbq%%\?*}"
PGVERNUM="${PG_VERSION_NUM:-1700}"

if [ -n "${PROJECT_CA_CERT:-}" ]; then
  CA_INDENTED="$(printf '%s' "$PROJECT_CA_CERT" | base64 -d | sed 's/^/        /')"
  TLS_JSON="      sslmode: verify-ca
      tlsConfigurationMethod: file-content
      tlsAuthWithCACert: true"
  TLS_SECRET="      tlsCACert: |
$CA_INDENTED"
else
  echo "WARN: PROJECT_CA_CERT not set, falling back to sslmode=require" >&2
  TLS_JSON="      sslmode: require"; TLS_SECRET=""
fi

mkdir -p /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards

cat > /etc/grafana/provisioning/datasources/pgwatch.yaml <<YAML
apiVersion: 1
datasources:
  - name: pgwatch metrics (postgres)
    uid: pgwatch-metrics
    type: grafana-postgresql-datasource
    access: proxy
    url: ${PGHOSTPORT}
    user: ${PGUSER}
    database: ${PGDATABASE}
    isDefault: true
    editable: false
    jsonData:
      postgresVersion: ${PGVERNUM}
${TLS_JSON}
    secureJsonData:
      password: ${PGPASSWORD}
${TLS_SECRET}
YAML

cat > /etc/grafana/provisioning/dashboards/pgwatch.yaml <<YAML
apiVersion: 1
providers:
  - name: pgwatch
    folder: pgwatch
    type: file
    allowUiUpdates: true
    updateIntervalSeconds: 60
    options:
      path: /var/lib/grafana/dashboards/pgwatch
YAML

exec /run.sh
