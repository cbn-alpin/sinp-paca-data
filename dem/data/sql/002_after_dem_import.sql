\echo 'Clean GeoNature Database after DEM import'
\echo 'Rights: owner of GeoNature database'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop useless "dem_files_tmp" table'
DROP TABLE IF EXISTS ref_geo.dem_files_tmp ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop temp french administrative region table'
DROP TABLE :areaTable;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;

\echo '-------------------------------------------------------------------------------'
\echo 'Rebuild DEM index'
REINDEX INDEX ref_geo.dem_st_convexhull_idx;
