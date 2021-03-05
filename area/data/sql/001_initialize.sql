-- Droits d'éxecution nécessaire : SUPER UTILISATEUR
-- Initialize database before insert SINP area data
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Add Postgis extensions if necessary'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;


\echo '----------------------------------------------------------------------------'
\echo 'Remove french administrative regions temporary table if necessary'
DROP TABLE IF EXISTS :areasTmpTable ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove subdivided SINP territory table if necessary'
DROP TABLE IF EXISTS :areaSubdividedTableName ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove geom index on subdivided SINP territory table'
DROP INDEX IF EXISTS ref_geo.idx_subdivided_sinp_area ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
