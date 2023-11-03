-- Script to export precisions percent by taxonomic groups
-- Usage (from local computer): cat ./precisions_percents_by_taxo_groups.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_taxo_groups_precisions.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

-- See function gn_synthese.get_precision_label() in utils_function.sql.

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
    )
    SELECT
        r.group_name AS groupe_taxo,
        ROUND((r.nbr_precis/nullif(r.total, 1)::float) * 100) AS pourcentage_precis,
        ROUND((r.nbr_lieudit/nullif(r.total, 1)::float) * 100) AS pourcentage_lieudit,
        ROUND((r.nbr_commune/nullif(r.total, 1)::float) * 100) AS pourcentage_commune,
        ROUND((r.nbr_indetermine/nullif(r.total, 1)::float) * 100) AS pourcentage_indetermine
    FROM (
        SELECT
            tg.group_name,
            COUNT(s.id_synthese) AS total,
            SUM(CASE WHEN gn_synthese.get_precision_label(s.precision) = 'précis' THEN 1 ELSE 0 END) AS nbr_precis,
            SUM(CASE WHEN gn_synthese.get_precision_label(s.precision) = 'lieu-dit' THEN 1 ELSE 0 END) AS nbr_lieudit,
            SUM(CASE WHEN gn_synthese.get_precision_label(s.precision) = 'commune' THEN 1 ELSE 0 END) AS nbr_commune,
            SUM(CASE WHEN gn_synthese.get_precision_label(s.precision) = 'indéterminé' THEN 1 ELSE 0 END) AS nbr_indetermine
        FROM gn_synthese.synthese AS s
            JOIN taxonomie.taxref AS t
                ON s.cd_nom = t.cd_nom
            JOIN taxo_groups AS tg
                ON t.cd_ref = ANY(tg.cd_refs)
        GROUP BY tg.group_name
    ) AS r
    ORDER BY r.group_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
