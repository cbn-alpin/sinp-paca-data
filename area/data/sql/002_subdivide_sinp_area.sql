-- Droits d'éxecution nécessaire : DB OWNER
-- Subdivize territory geom with st_subdivide() to faster st_intersect()
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add subdivided SINP territory table'
CREATE TABLE :areaSubdividedTableName AS
    SELECT
        random() AS gid,
        st_subdivide(geom, 255) AS geom
    FROM  :areasTmpTable
    WHERE insee_reg = :'sinpRegId' ;

\echo '----------------------------------------------------------------------------'
\echo 'Create geom index on subdivided SINP territory table'
CREATE INDEX idx_subdivided_sinp_area ON :areaSubdividedTableName USING gist (geom);

COMMIT;
