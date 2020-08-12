
-- Rights : GEONATURE DB OWNER
-- Create import table from source table.
BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Set storage to external on geometry column for source table'
-- Must speed up the st_intersect query (x5)
ALTER TABLE :importSchema.:sourceTable ALTER COLUMN flore_global_geom SET STORAGE EXTERNAL ;


\echo '----------------------------------------------------------------------------'
\echo 'Force geometry column to be updated for source table'
UPDATE :importSchema.:sourceTable
    SET flore_global_geom = ST_SetSRID(flore_global_geom, 2154) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add index on geom column of source table'
-- Need by the st_intersect query
CREATE INDEX idx_cbna_source_flore_global_geom
    ON :importSchema.:sourceTable
    USING gist(flore_global_geom) ;


\echo '----------------------------------------------------------------------------'
\echo 'Remove temp table with territory geom subdivided'
DROP TABLE IF EXISTS ref_geo.tmp_territory ;


\echo '----------------------------------------------------------------------------'
\echo 'Build temp table with territory geom subdivided'
CREATE TABLE ref_geo.tmp_territory AS
    SELECT ST_SubDivide(geom) AS geom
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('SINP')
    AND area_code = :'sinpRegId' ;


\echo '----------------------------------------------------------------------------'
\echo 'Add primary key on territory subdivided geom temp table'
ALTER TABLE ref_geo.tmp_territory ADD COLUMN gid SERIAL PRIMARY KEY ;


\echo '----------------------------------------------------------------------------'
\echo 'Add SRID on geom column for territory subdivided geom temp table'
ALTER TABLE ref_geo.tmp_territory ALTER COLUMN geom TYPE geometry(POLYGON, 2154) ;


\echo '----------------------------------------------------------------------------'
\echo 'Create the index on territory subdivided geom temp table'
CREATE INDEX idx_tmp_territory_geom ON ref_geo.tmp_territory USING gist(geom);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;


\echo '----------------------------------------------------------------------------'
\echo 'Vacuum analyse source table'
-- To speed up the st_intersect query
VACUUM ANALYZE :importSchema.:sourceTable ;


\echo '----------------------------------------------------------------------------'
\echo 'Vacuum analyse territory subdivided geom temp table'
VACUUM ANALYSE ref_geo.tmp_territory ;


\echo '----------------------------------------------------------------------------'
BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove import table'
DROP TABLE IF EXISTS :importSchema.:importTable;


\echo '----------------------------------------------------------------------------'
\echo 'Copy data from source table to import table'
CREATE TABLE :importSchema.:importTable AS (
    SELECT s.*
    FROM :importSchema.:sourceTable AS s, ref_geo.tmp_territory AS tt
    WHERE public.st_intersects(tt.geom, s.flore_global_geom)
) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
