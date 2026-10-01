-- Run as avnadmin on EACH Aiven PostgreSQL database you want to monitor.
-- Create the 'pgwatch' user with a strong password in the Aiven Console/API first
-- (Aiven restricts CREATE ROLE ... SUPERUSER, but pg_monitor is available).

GRANT pg_monitor TO pgwatch;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Optional, if you want query-level metrics from other DBs/schemas:
-- GRANT USAGE ON SCHEMA public TO pgwatch;
