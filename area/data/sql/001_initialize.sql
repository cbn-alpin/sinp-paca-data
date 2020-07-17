-- Droits d'éxecution nécessaire : SUPER UTILISATEUR
-- Initialize database before insert SINP area data
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Add Postgis extensions if necessary'
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;


\echo '----------------------------------------------------------------------------'
\echo 'Remove french administrative regions temporary table if necessary'
DROP TABLE IF EXISTS :areasTmpTable;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
