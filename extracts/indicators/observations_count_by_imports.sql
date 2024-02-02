-- Script to export inserted, updated, deleted observations count by SINP imports
-- Usage (from local computer): cat ./observations_count_by_imports.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_imports.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

-- See gn_imports.select_imports_stats inside utils_functions.sql script.

COPY (
    SELECT *
    FROM gn_imports.select_imports_stats()
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
