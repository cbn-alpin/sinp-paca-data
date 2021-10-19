-- Reinsert into cor_area_synthese link to municipalities.
--
-- Transfert this script on server this way:
-- rsync -av ./04_after_insert_admin_areas* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/04_after_insert_admin_areas*

BEGIN;

\echo ' Reinsert all data in cor_area_synthese for COM'
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        la.id_area
    FROM gn_synthese.tmp_outside_com AS toc
        JOIN gn_synthese.synthese AS s
            ON s.unique_id_sinp = toc.unique_id_sinp
        JOIN ref_geo.l_areas AS la
            ON st_intersects(la.geom, s.the_geom_local)
    WHERE la.id_type = ref_geo.get_id_area_type('COM')
ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

\echo ' Reinsert all data in cor_area_synthese for DEP'
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        la.id_area
    FROM gn_synthese.tmp_outside_dep AS tod
        JOIN gn_synthese.synthese AS s
            ON s.unique_id_sinp = tod.unique_id_sinp
        JOIN ref_geo.l_areas AS la
            ON st_intersects(la.geom, s.the_geom_local)
    WHERE la.id_type = ref_geo.get_id_area_type('DEP')
ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

COMMIT;
