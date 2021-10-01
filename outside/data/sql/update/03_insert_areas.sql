-- Insert new M1, M5 and M10 meshes into l_areas and li_grids.
--
-- Transfert this script on server this way:
-- rsync -av ./03_* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/03_*

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new M1 in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('M1') AS id_type,
        m1.code,
        m1.cd_sig,
        m1.geom,
        st_centroid(m1.geom),
        m1.geojson,
        True
    FROM ref_geo.tmp_m1 AS m1
        JOIN gn_synthese.tmp_outside_m1 AS om1
            ON (m1.geom && om1.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = m1.cd_sig
        );

\echo 'Insert new M1 in li_grids'
INSERT INTO ref_geo.li_grids (
    id_grid, id_area, cxmin, cxmax, cymin, cymax
)
    SELECT
        la.area_code,
        la.id_area,
        ST_XMin(la.geom),
        ST_XMax(la.geom),
        ST_YMin(la.geom),
        ST_YMax(la.geom)
    FROM ref_geo.l_areas AS la
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_grids AS lg
            WHERE lg.id_grid = la.area_code
        )
        AND la.id_type = ref_geo.get_id_area_type('M1') ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new M5 in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('M5') AS id_type,
        m5.code,
        m5.cd_sig,
        m5.geom,
        st_centroid(m5.geom),
        m5.geojson,
        True
    FROM ref_geo.tmp_m5 AS m5
        JOIN gn_synthese.tmp_outside_m5 AS om5
            ON (m5.geom && om5.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = m5.cd_sig
        );

\echo 'Insert new M5 (MARINE SOUTH-EAST) in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('M5') AS id_type,
        CONCAT('5kmL93-Marine-', m5.code5km),
        CONCAT('5kmL93M', m5.code5km),
        m5.geom,
        st_centroid(m5.geom),
        st_asgeojson(st_transform(m5.geom, 4326)),
        True
    FROM ref_geo.tmp_m5_marine AS m5
        JOIN gn_synthese.tmp_outside_m5 AS om5
            ON (m5.geom && om5.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = ('5kmL93M' || m5.code5km)
        ) ;

\echo 'Insert all new M5 in li_grids'
INSERT INTO ref_geo.li_grids (
    id_grid, id_area, cxmin, cxmax, cymin, cymax
)
    SELECT
        la.area_code,
        la.id_area,
        ST_XMin(la.geom),
        ST_XMax(la.geom),
        ST_YMin(la.geom),
        ST_YMax(la.geom)
    FROM ref_geo.l_areas AS la
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_grids AS lg
            WHERE lg.id_grid = la.area_code
        )
        AND la.id_type = ref_geo.get_id_area_type('M5') ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new M10 in l_areas'
INSERT INTO ref_geo.l_areas (
    id_type, area_name, area_code, geom, centroid, geojson_4326, "enable"
)
    SELECT DISTINCT
        ref_geo.get_id_area_type('M10') AS id_type,
        m10.code,
        m10.cd_sig,
        m10.geom,
        st_centroid(m10.geom),
        m10.geojson,
        True
    FROM ref_geo.tmp_m10 AS m10
        JOIN gn_synthese.tmp_outside_m10 AS om10
            ON (m10.geom && om10.the_geom_local)
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = m10.cd_sig
        ) ;

\echo 'Insert new M10 in li_grids'
INSERT INTO ref_geo.li_grids (
    id_grid, id_area, cxmin, cxmax, cymin, cymax
)
    SELECT
        la.area_code,
        la.id_area,
        ST_XMin(la.geom),
        ST_XMax(la.geom),
        ST_YMin(la.geom),
        ST_YMax(la.geom)
    FROM ref_geo.l_areas AS la
    WHERE NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_grids AS lg
            WHERE lg.id_grid = la.area_code
        )
        AND la.id_type = ref_geo.get_id_area_type('M10') ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
