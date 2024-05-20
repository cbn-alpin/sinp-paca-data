-- Script to export osbervations counts by municipalities
-- Usage (from local computer): cat ./observations_count_by_municipalities.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_counts_by_municipalities.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    SELECT
        a.area_name,
        a.area_code,
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN gn_synthese.cor_area_synthese AS cas
            ON cas.id_synthese = s.id_synthese
        JOIN ref_geo.l_areas AS a
            ON (cas.id_area = a.id_area AND a.id_type = ref_geo.get_id_area_type_by_code('COM'))
    GROUP BY a.area_name, a.area_code
    ORDER BY obs_nbr DESC
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
