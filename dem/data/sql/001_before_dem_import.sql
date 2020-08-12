\echo 'Pepare GeoNature Database to DEM import'
\echo 'Rights: owner of GeoNature database'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean "dem" GeoNature table'
TRUNCATE TABLE ref_geo.dem RESTART IDENTITY ;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean "dem_vector" GeoNature table'
TRUNCATE TABLE ref_geo.dem_vector RESTART IDENTITY ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop "dem_files_tmp" table if exists (due to previous script error)'
DROP TABLE IF EXISTS ref_geo.dem_files_tmp ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create table "dem_files_tmp"'
CREATE TABLE ref_geo.dem_files_tmp (
    file character varying(100) PRIMARY KEY,
    geom public.geometry(Geometry, :localSrid})
);

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
