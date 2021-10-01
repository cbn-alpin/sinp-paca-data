-- Set to NULL geom of observations without M5 meshes
-- This observations have:
-- - an empty geometry
-- - a geometry in error
-- - a geometry outside the SINP area
--
-- Transfert this script on server this way:
-- rsync -av ./06_* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d gn2_dev_sinp -f ~/data/outside/data/sql/update/06_*


BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Number of observations with geom but not linked to M5 meshes:'
SELECT count(id_synthese)
FROM gn_synthese.tmp_outside_after_m5 AS oam5
WHERE oam5.the_geom_local IS NOT NULL ;

\echo '----------------------------------------------------------------------------'
\echo 'Set to NULL geom of observations not linked to M5 meshes'
UPDATE gn_synthese.synthese AS s
    SET the_geom_4326 = NULL,
        the_geom_point = NULL,
        the_geom_local = NULL
    WHERE id_synthese IN (
        SELECT id_synthese
        FROM gn_synthese.tmp_outside_after_m5 AS oam5
        WHERE oam5.the_geom_local IS NOT NULL
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
