-- Droits d'éxecution nécessaire : DB OWNER
-- Subdivize territory geom with st_subdivide() to faster st_intersect()
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add subdivided SINP territory table from ref_geo.l_areas'
CREATE TABLE :areaSubdividedTableName AS
    SELECT
        random() AS gid,
        st_subdivide(geom, 255) AS geom
    FROM  ref_geo.l_areas
    WHERE area_code = :'sinpRegId'
        AND id_type = ref_geo.get_id_area_type('SINP') ;

\echo '----------------------------------------------------------------------------'
\echo 'Create geom index on subdivided SINP territory table'
CREATE INDEX idx_subdivided_sinp_area ON :areaSubdividedTableName USING gist (geom);

COMMIT;
