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
\echo 'Disable all status text not used for SINP PACA territory'
UPDATE taxonomie.bdc_statut_text
SET enable = false
WHERE cd_doc NOT IN (
    366749, 901, 738, 758, 763, 625, 633, 3561, 643, 713, 716, 730, 731,
    703, 694, 694, 732, 733, 174768, 174769, 174770, 195368, 268129,
    268409, 146732, 145082, 196448, 158248, 755, 756, 358269, 358270,
    160321, 275396, 31345, 138062, 31343, 300831, 138065, 87486, 165208,
    87625, 31341, 87619, 138063, 144173, 220350, 321049, 208629, 87484,
    146311, 88261, 300212, 146310, 31346, 249369, 138064
) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
