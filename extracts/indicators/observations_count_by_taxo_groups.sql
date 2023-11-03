-- Script to export stats by taxonomic groups
-- Usage (from local computer): cat ./observations_count_by_taxo_groups.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_taxo_groups_stats.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH taxo_groups AS (
        SELECT group_name, cd_refs
        FROM (
            VALUES
                ('Animalia - Vertébrés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata')
                ),
                ('Animalia - Invertébrés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum IN ('Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes'))
                ),
                ('Animalia - Autres', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum NOT IN ('Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes', 'Chordata'))
                ),
                ('Fungi', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Fungi')
                ),
                ('Plantae - Trachéophytes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Trachéophytes')
                ),
                ('Plantae - Bryophytes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Bryophytes')
                ),
                ('Plantae - Algues', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Algues')
                ),
                ('Plantae - Autres', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Autres')
                ),
                ('Archaea', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Archaea')
                ),
                ('Bacteria', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Bacteria')
                ),
                ('Chromista', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Chromista')
                ),
                ('Protozoa', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Protozoa')
                )
        ) AS tg (group_name, cd_refs)
    ),
    groups_counts AS (
        SELECT
            r.group_name,
            COUNT(r.nbre) AS taxon_nbr,
            SUM(r.nbre) AS obs_nbr
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
    )
    SELECT
        group_name AS groupe,
        taxon_nbr AS taxon_nbre,
        obs_nbr AS obs_nbre
    FROM (
        SELECT
            group_name,
            taxon_nbr,
            obs_nbr,
            0 AS sort_order
        FROM groups_counts

        UNION

        SELECT
            'Total' AS group_name,
            SUM(taxon_nbr) AS taxon_nbr,
            SUM(obs_nbr) AS obs_nbr,
            1 AS sort_order
        FROM groups_counts
    ) AS counts_and_total
    ORDER BY sort_order, group_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
