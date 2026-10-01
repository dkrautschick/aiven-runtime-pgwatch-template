#!/bin/sh
# Maps the Aiven PG integration (DATABASE_URL, PROJECT_CA_CERT) to pgwatch's PW_* settings.
set -eu

: "${DATABASE_URL:?DATABASE_URL missing - add a pg service integration with env_key DATABASE_URL}"
: "${PW_WEBPASSWORD:?PW_WEBPASSWORD missing - set it as a secret env var}"
export PW_WEBUSER="${PW_WEBUSER:-admin}"
export PW_WEBPASSWORD

uri="$DATABASE_URL"
if [ -n "${PROJECT_CA_CERT:-}" ]; then
  printf '%s' "$PROJECT_CA_CERT" | base64 -d > /tmp/aiven-ca.pem
  # replace Aiven's sslmode=require with CA-verified TLS
  uri="${uri%%\?*}?sslmode=verify-ca&sslrootcert=/tmp/aiven-ca.pem"
else
  echo "WARN: PROJECT_CA_CERT not set, TLS server certificate is NOT verified" >&2
fi

# Config store and metrics sink share one Aiven PG database by default.
# Override PW_SOURCES / PW_SINK to split them.
export PW_SOURCES="${PW_SOURCES:-$uri}"
export PW_SINK="${PW_SINK:-$uri}"
export PW_WEBADDR="${PW_WEBADDR:-:8080}"

PW=/pgwatch/pgwatch

# Idempotent bootstrap: create schema on first start, apply migrations afterwards
"$PW" config init    || echo "config init skipped (already initialised?)" >&2
"$PW" config upgrade || echo "config upgrade: nothing to do or failed, see log" >&2

exec "$PW"
