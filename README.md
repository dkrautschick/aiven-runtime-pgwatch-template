# pgwatch v6 on Aiven (Application service template)

Pinned: pgwatch **6.0.0** (image `cybertecpostgresql/pgwatch:6.0.0`, Alpine, entrypoint `/pgwatch/pgwatch`) and Grafana **13.1.7** with the v13 dashboards from the same tag.

Two Aiven Application services + one Aiven for PostgreSQL service:

```
 monitored Aiven PG ──(pg_monitor user)──▶  pgwatch-agent  ──▶  Aiven PG "pgwatch-store"  ◀── pgwatch-grafana
                                           (WebUI :8080)       (config + metrics)            (dashboards :3000)
```

| Service | Containerfile | build_path | port | integration | secrets |
|---|---|---|---|---|---|
| `pgwatch-agent` | `pgwatch/Dockerfile` | `pgwatch` | 8080 | pg → `DATABASE_URL` | `PW_WEBPASSWORD` (+ `PW_WEBUSER`, default `admin`) |
| `pgwatch-grafana` | `grafana/Dockerfile` | `grafana` | 3000 | pg → `DATABASE_URL` | `GF_SECURITY_ADMIN_PASSWORD` |

## Steps
1. Push this repo to GitHub (connect the Aiven VCS integration if private).
2. Create/choose the **store** PG service (a small dedicated plan is enough; retention is 14 days by default, `PW_RETENTION`).
3. Deploy both app services in the **same cloud region/VPC** as the store.
4. Open the agent WebUI, add each monitored Aiven PG (user `pgwatch`, `sslmode=require`, start with preset `basic`). Run `sql/monitored_db_setup.sql` on each target.
5. Open Grafana, folder **pgwatch**.

## Networking
The agent must reach the monitored PG services. If those use IP allow-lists or a VPC, put the agent in the same VPC or allow its egress IPs.

## Verified against the v6.0.0 source tree
- Upstream image is `FROM alpine`, binary at `/pgwatch/pgwatch`, `EXPOSE 8080` (busybox gives us `/bin/sh` and `base64`).
- `config init` / `config upgrade` subcommands exist; with `PW_SOURCES` set to a PG URI and `PW_METRICS` unset, metrics definitions are read from that same config DB.
- All 25 v13 Postgres dashboards reference datasource uid `pgwatch-metrics`, type `grafana-postgresql-datasource` (matches the provisioned datasource).
- Upstream compose uses `grafana/grafana:13.1`, plugin `marcusolsson-treemap-panel`, feature toggle `dashboardNewLayouts`; all three are in the Grafana Dockerfile.

## Not yet verified (check on first build)
- `config init` re-run behaviour on an already initialised DB (entrypoint tolerates failure, then runs `config upgrade`).
- Plugin install at build time needs network egress during the Aiven image build.
- Which pgwatch presets work with Aiven's restricted superuser model.
- Want to downgrade? Set `PGWATCH_VERSION=5.3.0` in both Dockerfiles and switch the tarball path to `grafana/postgres/v12` + Grafana 12.x.

## Hardening ideas
- Put WebUI/Grafana behind SSO or an allow-list; both are public by default on Aiven apps.
- Persist Grafana state in a separate PG database (`GF_DATABASE_*`).
