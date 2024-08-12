-- Disable all status text not used for SINP PACA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./04_* geonat@db-paca-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/04_*
-- See: https://github.com/cbn-alpin/sinp-paca-tickets/issues/182
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable all status text'
UPDATE taxonomie.bdc_statut_text
SET "enable" = false ;

\echo '----------------------------------------------------------------------------'
\echo 'Enable all status text used for SINP PACA territory'
UPDATE taxonomie.bdc_statut_text AS s
SET "enable" = true
FROM taxonomie.bdc_statut_cor_text_area AS ct
    JOIN ref_geo.l_areas AS la
        ON ct.id_area = la.id_area
WHERE s.id_text = ct.id_text
    AND la.id_type = ref_geo.get_id_area_type('DEP')
    AND la.area_code IN ('04', '05', '06', '13', '83', '84')
    AND cd_type_statut IN (
        'LRM', 'LRE', 'LRN', 'LRR', 'ZDET', 'DO', 'DH', 'REGL', 'REGLLUTTE', 'PN', 'PR', 'PD'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
