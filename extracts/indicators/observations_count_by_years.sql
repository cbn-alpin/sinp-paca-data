-- Script to export osbervations counts by year
-- Usage (from local computer): cat ./observations_count_by_years.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_counts.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    WITH years AS (
        SELECT DISTINCT y.annee
        FROM (
            SELECT DISTINCT DATE_PART('Year', s1.meta_create_date) AS annee
            FROM gn_synthese.synthese AS s1
            UNION
            SELECT DISTINCT DATE_PART('Year', s2.meta_update_date) AS annee
            FROM gn_synthese.synthese AS s2
        ) AS y
    ),
    created_obs AS (
        SELECT
            DATE_PART('Year', s.meta_create_date) AS annee,
            COUNT(s.id_synthese) AS observations_nbre
        FROM gn_synthese.synthese AS s
        GROUP BY DATE_PART('Year', s.meta_create_date)
        ORDER BY DATE_PART('Year', s.meta_create_date) DESC
    ),
    updated_obs AS (
        SELECT
            DATE_PART('Year', s.meta_update_date) AS annee,
            COUNT(s.id_synthese) AS observations_nbre
        FROM gn_synthese.synthese AS s
        GROUP BY DATE_PART('Year', s.meta_update_date)
        ORDER BY DATE_PART('Year', s.meta_update_date) DESC
    )
    SELECT
        y.annee,
        c.observations_nbre AS ajout_obs_nbre,
        u.observations_nbre AS mise_a_jour_obs_nbre
    FROM years AS y
        LEFT JOIN created_obs AS c
            ON y.annee = c.annee
        LEFT JOIN updated_obs AS u
            ON y.annee = u.annee
    WHERE y.annee IS NOT NULL
    ORDER BY y.annee DESC
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
