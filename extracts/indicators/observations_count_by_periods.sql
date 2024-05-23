-- Script to export observation counts by periods (before 1801, 1801-1900, 1901-1950, 1951-2000,2001-2010, after 2010)
-- Usage (from local computer): cat ./observations_count_by_periods.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_periods.csv
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
    )
    SELECT r.*
    FROM (
        SELECT
            tg.group_name,
            SUM(CASE WHEN date_max < '1801-01-01' THEN 1 ELSE 0 END) AS avant_1801,
            SUM(CASE WHEN date_min >= '1801-01-01' AND date_max < '1901-01-01' THEN 1 ELSE 0 END) AS de_1801_a_1900,
            SUM(CASE WHEN date_min >= '1901-01-01' AND date_max < '1951-01-01' THEN 1 ELSE 0 END) AS de_1901_a_1950,
            SUM(CASE WHEN date_min >= '1951-01-01' AND date_max < '2001-01-01' THEN 1 ELSE 0 END) AS de_1951_a_2000,
            SUM(CASE WHEN date_min >= '2001-01-01' AND date_max < '2011-01-01' THEN 1 ELSE 0 END) AS de_2001_a_2010,
            SUM(CASE WHEN date_min >= '2011-01-01' THEN 1 ELSE 0 END) AS apres_2010,
            COUNT(s.id_synthese) AS total
        FROM gn_synthese.synthese AS s
            JOIN taxonomie.taxref AS t
                ON s.cd_nom = t.cd_nom
            JOIN taxo_groups AS tg
                ON t.cd_ref = ANY(tg.cd_refs)
        GROUP BY tg.group_name
        ORDER BY tg.group_name
    ) AS r

    UNION ALL

    SELECT
        'Global' AS group_name,
        SUM(CASE WHEN date_max < '1801-01-01' THEN 1 ELSE 0 END) AS avant_1801,
        SUM(CASE WHEN date_min >= '1801-01-01' AND date_max < '1901-01-01' THEN 1 ELSE 0 END) AS de_1801_a_1900,
        SUM(CASE WHEN date_min >= '1901-01-01' AND date_max < '1951-01-01' THEN 1 ELSE 0 END) AS de_1901_a_1950,
        SUM(CASE WHEN date_min >= '1951-01-01' AND date_max < '2001-01-01' THEN 1 ELSE 0 END) AS de_1951_a_2000,
        SUM(CASE WHEN date_min >= '2001-01-01' AND date_max < '2011-01-01' THEN 1 ELSE 0 END) AS de_2001_a_2010,
        SUM(CASE WHEN date_min >= '2011-01-01' THEN 1 ELSE 0 END) AS apres_2010,
        COUNT(s.id_synthese) AS total
    FROM gn_synthese.synthese AS s
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
