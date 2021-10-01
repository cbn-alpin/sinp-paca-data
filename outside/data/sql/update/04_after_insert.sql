-- Reinsert into cor_area_synthese link to M10, M5 and M1 meshes.
--
-- Transfert this script on server this way:
-- rsync -av ./04_* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/04_*

BEGIN;

\echo ' Reinsert all data in cor_area_synthese for meshes M1'
-- ~3s for ~600 areas and ~14000 observations on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        la.id_area
    FROM gn_synthese.tmp_outside_m1 AS tom
		JOIN gn_synthese.synthese AS s
			ON s.unique_id_sinp = tom.unique_id_sinp
		JOIN ref_geo.l_areas AS la
			ON (la.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE la.id_type = ref_geo.get_id_area_type('M1')
ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

\echo ' Reinsert all data in cor_area_synthese for meshes M5'
-- <1s for ~150 areas and ~1 600 observations on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        la.id_area
    FROM gn_synthese.tmp_outside_m5 AS tom
		JOIN gn_synthese.synthese AS s
			ON s.unique_id_sinp = tom.unique_id_sinp
		JOIN ref_geo.l_areas AS la
			ON (la.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE la.id_type = ref_geo.get_id_area_type('M5')
ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

\echo ' Reinsert all data in cor_area_synthese for meshes M10'
-- <1s for ~140 areas and ~1 100 observations on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        la.id_area
    FROM gn_synthese.tmp_outside_m10 AS tom
		JOIN gn_synthese.synthese AS s
			ON s.unique_id_sinp = tom.unique_id_sinp
		JOIN ref_geo.l_areas AS la
			ON (la.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE la.id_type = ref_geo.get_id_area_type('M10')
ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

COMMIT;
