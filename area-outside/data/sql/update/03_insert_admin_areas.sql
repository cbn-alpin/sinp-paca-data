-- Insert new admin areas into l_areas and li_municipalities.
--
-- Transfert this script on server this way:
-- rsync -av ./03_insert_admin_areass* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/03_insert_admin_areas*

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new COM in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('COM') AS id_type,
        m.nom_com,
        m.insee_com,
        m.geom,
        st_centroid(m.geom),
        m.geojson,
        True
    FROM ref_geo.tmp_municipalities AS m
        JOIN gn_synthese.tmp_outside_com AS om
            ON st_intersects(m.geom, om.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = m.insee_com
                AND la.id_type = ref_geo.get_id_area_type('COM')
        )
        AND substring(m.insee_com FROM 1 FOR 2) IN ('84', '83', '13', '06', '05', '04') ;

\echo 'Insert new COM in li_municipalities'
INSERT INTO ref_geo.li_municipalities (
    id_municipality, id_area, "status", insee_com, nom_com, insee_arr, insee_dep, insee_reg, code_epci
)
    SELECT id, la.id_area, statut, insee_com, nom_com, insee_arr, insee_dep, insee_reg, code_epci
    FROM ref_geo.tmp_municipalities AS t
        JOIN ref_geo.l_areas AS la ON la.area_code = t.insee_com
    WHERE la.id_type = ref_geo.get_id_area_type('COM')
        AND substring(t.insee_com FROM 1 FOR 2) IN ('84', '83', '13', '06', '05', '04')
        AND NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_municipalities AS lm
            WHERE lm.id_area = la.id_area
        ) ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new DEP in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('DEP') AS id_type,
        m.nom_dep,
        m.insee_dep,
        m.geom,
        st_centroid(m.geom),
        m.geojson,
        True
    FROM ref_geo.tmp_departements AS m
        JOIN gn_synthese.tmp_outside_dep AS od
            ON st_intersects(m.geom, od.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = m.insee_dep
                AND la.id_type = ref_geo.get_id_area_type('DEP')
        )
        AND m.insee_dep IN ('84', '83', '13', '06', '05', '04') ;

\echo '----------------------------------------------------------------------------'
\echo 'Reindex l_areas geom'
REINDEX INDEX ref_geo.index_l_areas_geom ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
