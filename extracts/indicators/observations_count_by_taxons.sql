-- Script to export osbervations counts by taxons
-- Usage (from local computer): cat ./observations_count_by_taxons.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_counts_by_taxons.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    SELECT
        t2.cd_nom AS sciname_code,
        t2.lb_nom AS sciname,
        t2.nom_vern AS vernaname,
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN taxonomie.taxref AS t1
            ON t1.cd_nom = s.cd_nom
        JOIN taxonomie.taxref AS t2
            ON t2.cd_nom = t1.cd_ref
    GROUP BY t2.lb_nom, t2.cd_nom
    ORDER BY obs_nbr DESC
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
