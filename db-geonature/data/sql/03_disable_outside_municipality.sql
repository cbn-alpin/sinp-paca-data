-- Disable all municipalities outside SINP PACA territory.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./03_* geonat@db-paca-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/03_*
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable all municipalities outside SINP PACA territory'
UPDATE ref_geo.l_areas
    SET "enable" = False
    WHERE id_type = ref_geo.get_id_area_type('COM')
        AND substring(area_code FROM 1 FOR 2) NOT IN ('84',' 83', '13', '06', '05', '04') ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
