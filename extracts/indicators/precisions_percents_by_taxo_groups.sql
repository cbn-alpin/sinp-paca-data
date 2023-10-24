-- Script to export precisions percent by taxonomic groups
-- Usage (from local computer): cat ./precisions_percents_by_taxo_groups.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_taxo_groups_precisions.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

-- CREATE OR REPLACE FUNCTION gn_synthese.get_precision_label(precision_value integer)
--  RETURNS varchar
--  LANGUAGE plpgsql
--  IMMUTABLE
-- AS $function$
--     -- Function which return the precision label from a precision value in meter
--     DECLARE precisionLabel varchar;

--     BEGIN
--         SELECT INTO precisionLabel
--             CASE
--                 WHEN precision_value <= 25 THEN 'précis'
--                 WHEN precision_value > 25 AND precision_value <= 250  THEN 'lieu-dit'
--                 WHEN precision_value > 250 THEN 'commune'
--                 ELSE 'indéterminé'
--             END ;

--         RETURN precisionLabel ;
--     END;
-- $function$ ;


COPY (
    WITH taxo_groups AS (
        SELECT group_name, cd_refs
        FROM (
            VALUES
                ('Vertébrés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata')
                ),
                ('Invertébrés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum IN ('Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes'))
                ),
                ('Champignons', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Fungi')
                ),
                ('Trachéophytes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Trachéophytes')
                ),
                ('Bryophytes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Bryophytes')
                ),
                ('Algues', ARRAY(
                    SELECT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Plantae'
                        AND group1_inpn = 'Algues')
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
