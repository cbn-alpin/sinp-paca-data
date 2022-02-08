-- Script to export stats by taxonomic groups
-- Usage (from local computer): cat ./taxo_groups_stats.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_taxo_groups_stats.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH taxo_groups AS (
        SELECT group_name, cd_refs
        FROM (
            VALUES
                ('Vertébrés', ARRAY(SELECT cd_ref FROM taxonomie.find_all_taxons_children(ARRAY[185694]))),
                ('Invertébrés', ARRAY(SELECT cd_ref FROM taxonomie.find_all_taxons_children(ARRAY[183751, 183818, 186296, 186320, 186776]))),
                ('Trachéophytes', ARRAY(SELECT cd_ref FROM taxonomie.find_all_taxons_children(ARRAY[846225]))),
                ('Bryophytes', ARRAY(SELECT cd_ref FROM taxonomie.find_all_taxons_children(ARRAY[187105]))),
                ('Champignons', ARRAY(SELECT cd_ref FROM taxonomie.find_all_taxons_children(ARRAY[187496])))
        ) AS tg (group_name, cd_refs)
    )
    SELECT
        r.group_name,
        COUNT(r.nbre) AS taxon_nbre,
        SUM(r.nbre) AS obs_nbre
    FROM (
        SELECT tg.group_name, COUNT(s.id_synthese) AS nbre
        FROM gn_synthese.synthese AS s
            JOIN taxonomie.taxref AS t
                ON s.cd_nom = t.cd_nom
            JOIN taxo_groups AS tg
                ON t.cd_ref = ANY(tg.cd_refs)
        GROUP BY tg.group_name, t.cd_ref
    ) AS r
    GROUP BY r.group_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
