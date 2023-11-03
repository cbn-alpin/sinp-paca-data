-- Script to export observations count by departments and kingdoms
-- Usage (from local computer): cat ./observatins_count_by_departments.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_departments.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH kingdoms_counts AS (
        SELECT
            la.area_code,
            la.area_name,
            t.regne AS kingdom,
            COUNT(s.id_synthese) AS obs_nbr
        FROM gn_synthese.synthese AS s
            JOIN gn_synthese.cor_area_synthese AS cas
                ON s.id_synthese = cas.id_synthese
            JOIN ref_geo.l_areas AS la
                ON la.id_area = cas.id_area
            JOIN ref_geo.bib_areas_types AS bat
                ON bat.id_type = la.id_type
            JOIN taxonomie.taxref AS t
                ON t.cd_nom = s.cd_nom
        WHERE bat.type_code = 'DEP'
        GROUP BY la.area_code, la.area_name, t.regne
    )
    SELECT
        area_code AS code_dept,
        area_name AS dept,
        kingdom AS regne,
        obs_nbr AS obs_nbre
    FROM (
        SELECT
            area_code,
            area_name,
            kingdom,
            obs_nbr,
            0 AS sort_order
        FROM kingdoms_counts

        UNION

        SELECT
            kc.area_code,
            kc.area_name,
            'Total' AS kingdom,
            SUM(kc.obs_nbr) AS obs_nbr,
            1 AS sort_order
        FROM kingdoms_counts AS kc
        GROUP BY kc.area_code, kc.area_name
    ) AS counts_and_total
    ORDER BY area_code, sort_order, kingdom
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
