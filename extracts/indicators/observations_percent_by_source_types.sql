-- Script to export observation percents by source types (Collection/Litterature//Fields/Unknown)
-- Usage (from local computer): cat ./observations_percent_by_source_types.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_source_types_percents.csv
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
    SELECT
        r.group_name AS groupe_taxo,
        ROUND((r.nbr_collection/nullif(r.total, 1)::float) * 100) AS pourcentage_collection,
        ROUND((r.nbr_litterature/nullif(r.total, 1)::float) * 100) AS pourcentage_litterature,
        ROUND((r.nbr_inconnu/nullif(r.total, 1)::float) * 100) AS pourcentage_inconnu,
        ROUND((r.nbr_terrain/nullif(r.total, 1)::float) * 100) AS pourcentage_terrain
    FROM (
        SELECT
            tg.group_name,
            COUNT(s.id_synthese) AS total,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Co' THEN 1 ELSE 0 END) AS nbr_collection,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Li' THEN 1 ELSE 0 END) AS nbr_litterature,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'NSP' THEN 1 ELSE 0 END) AS nbr_inconnu,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Te' THEN 1 ELSE 0 END) AS nbr_terrain
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
        r.group_name AS groupe_taxo,
        ROUND((r.nbr_collection/nullif(r.total, 1)::float) * 100, 1) AS pourcentage_collection,
        ROUND((r.nbr_litterature/nullif(r.total, 1)::float) * 100, 1) AS pourcentage_litterature,
        ROUND((r.nbr_inconnu/nullif(r.total, 1)::float) * 100, 1) AS pourcentage_inconnu,
        ROUND((r.nbr_terrain/nullif(r.total, 1)::float) * 100, 1) AS pourcentage_terrain
    FROM (
        SELECT
            'Global' AS group_name,
            COUNT(s.id_synthese) AS total,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Co' THEN 1 ELSE 0 END) AS nbr_collection,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Li' THEN 1 ELSE 0 END) AS nbr_litterature,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'NSP' THEN 1 ELSE 0 END) AS nbr_inconnu,
            SUM(CASE WHEN ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_source_status) = 'Te' THEN 1 ELSE 0 END) AS nbr_terrain
        FROM gn_synthese.synthese AS s
    ) AS r
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
