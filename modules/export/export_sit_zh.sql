--Voici les données concernées pour cet export :
--•	données précises (ni lieu-dit ni communale) de moins de 20 ans ayant un statut
--        (protégée et/ou menacée CR, EN, VU)
--•	les données privées à diffusion restreinte doivent également être exclues de cet export si la ZH
--      est < à 5x5km (pour ne pas que ces données soient disponibles plus précisément au grand public
--      via cette plateforme que via Silene)
--•	les données sensibles doivent être exclues de cet export

CREATE MATERIALIZED VIEW
    gn_exports.sit_zh_taxon AS
WITH
    --liste des taxons protection nationale, régionale et cotation uicn cr, en, vu
    nationally_protected_taxa AS (
        SELECT DISTINCT
            cd_ref
        FROM
            (
                SELECT DISTINCT
                    tx.cd_ref
                FROM
                    taxonomie.bdc_statut_text AS t
                    JOIN taxonomie.bdc_statut_cor_text_values AS tv ON tv.id_text = t.id_text
                    JOIN taxonomie.bdc_statut_values AS v ON v.id_value = tv.id_value
                    JOIN taxonomie.bdc_statut_taxons AS tx ON tx.id_value_text = tv.id_value_text
                WHERE
                    t."enable" = TRUE
                    AND t.cd_type_statut = 'LRR'
                    AND v.code_statut IN ('CR', 'EN', 'VU')
                UNION
                SELECT DISTINCT
                    tx.cd_ref
                FROM
                    taxonomie.bdc_statut_text AS t
                    JOIN taxonomie.bdc_statut_cor_text_values AS tv ON tv.id_text = t.id_text
                    JOIN taxonomie.bdc_statut_taxons AS tx ON tx.id_value_text = tv.id_value_text
                WHERE
                    t."enable" = TRUE
                    AND t.cd_type_statut = 'PN' -- Protection nationale
                UNION
                SELECT DISTINCT
                    tx.cd_ref
                FROM
                    taxonomie.bdc_statut_text AS t
                    JOIN taxonomie.bdc_statut_cor_text_values AS tv ON tv.id_text = t.id_text
                    JOIN taxonomie.bdc_statut_taxons AS tx ON tx.id_value_text = tv.id_value_text
                WHERE
                    t."enable" = TRUE
                    AND t.cd_type_statut = 'PR' -- Protection régionale
            ) AS protected
    ),
    --liste des taxons en protection départementales
    departmentally_protected_taxa AS (
        SELECT DISTINCT
            tx.cd_ref,
            ta.id_area
        FROM
            taxonomie.bdc_statut_text AS t
            JOIN taxonomie.bdc_statut_cor_text_values AS tv ON tv.id_text = t.id_text
            JOIN taxonomie.bdc_statut_values AS v ON v.id_value = tv.id_value
            JOIN taxonomie.bdc_statut_taxons AS tx ON tx.id_value_text = tv.id_value_text
            JOIN taxonomie.bdc_statut_cor_text_area AS ta ON t.id_text = ta.id_text
        WHERE
            t."enable" = TRUE
            AND t.cd_type_statut = 'PD' -- Protection départementale
    ),
    nationally_protected_observations_in_wetlands AS (
        SELECT DISTINCT
            t.cd_ref,
            t.nom_valide,
            z.code,
            z.main_name
        FROM
            ref_geo.sit_zones_humides AS z
            JOIN gn_synthese.synthese AS s ON (
                s.the_geom_local && z.geom
                AND st_within (s.the_geom_local, z.geom)
            )
            JOIN taxonomie.taxref AS t ON t.cd_nom = s.cd_nom
            JOIN nationally_protected_taxa AS npt ON npt.cd_ref = t.cd_ref
        WHERE
            z.surface_km2 >= 25
            AND s.additional_data @> '{"precisionLabel": "précis"}'::jsonb
            AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
            AND s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature ('SENSIBILITE', '0') -- sauf données sensibles
        UNION
        SELECT DISTINCT
            t.cd_ref,
            t.nom_valide,
            z.code,
            z.main_name
        FROM
            ref_geo.sit_zones_humides AS z
            JOIN gn_synthese.synthese AS s ON (
                s.the_geom_local && z.geom
                AND st_within (s.the_geom_local, z.geom)
            )
            JOIN taxonomie.taxref AS t ON t.cd_nom = s.cd_nom
            JOIN nationally_protected_taxa AS npt ON npt.cd_ref = t.cd_ref
        WHERE
            z.surface_km2 < 25
            AND s.additional_data @> '{"precisionLabel": "précis"}'::jsonb
            AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
            AND s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature ('SENSIBILITE', '0') -- sauf données sensibles
            AND s.id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature ('NIV_PRECIS', '5') -- sauf données privées et floutées
    ),
    departmentally_protected_observations_in_wetlands AS (
        SELECT DISTINCT
            t.cd_ref,
            t.nom_valide,
            z.code,
            z.main_name
        FROM
            ref_geo.sit_zones_humides AS z
            JOIN gn_synthese.synthese AS s ON (
                s.the_geom_local && z.geom
                AND st_within (s.the_geom_local, z.geom)
            )
            JOIN taxonomie.taxref AS t ON t.cd_nom = s.cd_nom
            JOIN gn_synthese.cor_area_synthese AS csa ON csa.id_synthese = s.id_synthese
            JOIN departmentally_protected_taxa AS dpt ON (
                dpt.cd_ref = t.cd_ref
                AND dpt.id_area = csa.id_area
            )
        WHERE
            z.surface_km2 >= 25
            AND s.additional_data @> '{"precisionLabel": "précis"}'
            AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
            AND s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature ('SENSIBILITE', '0') -- sauf données sensibles
        UNION
        SELECT DISTINCT
            t.cd_ref,
            t.nom_valide,
            z.code,
            z.main_name
        FROM
            ref_geo.sit_zones_humides AS z
            JOIN gn_synthese.synthese s ON (
                s.the_geom_local && z.geom
                AND st_within (s.the_geom_local, z.geom)
            )
            JOIN taxonomie.taxref AS t ON t.cd_nom = s.cd_nom
            JOIN gn_synthese.cor_area_synthese AS csa ON csa.id_synthese = s.id_synthese
            JOIN departmentally_protected_taxa AS dpt ON (
                dpt.cd_ref = t.cd_ref
                AND dpt.id_area = csa.id_area
            )
        WHERE
            z.surface_km2 < 25
            AND s.additional_data @> '{"precisionLabel": "précis"}'
            AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
            AND s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature ('SENSIBILITE', '0') -- sauf données sensibles
            AND s.id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature ('NIV_PRECIS', '5') -- sauf données privées et floutées
    )
SELECT DISTINCT
    code AS code_zh,
    main_name AS nom_zh,
    cd_ref,
    nom_valide
FROM
    (
        SELECT
            *
        FROM
            departmentally_protected_observations_in_wetlands
        UNION
        SELECT
            *
        FROM
            nationally_protected_observations_in_wetlands
    ) AS observations
WITH
    DATA;

CREATE UNIQUE INDEX sit_zh_taxon_pk ON gn_exports.sit_zh_taxon USING btree (code_zh, cd_ref);

CREATE INDEX sit_zh_taxon_cd_ref_idx ON gn_exports.sit_zh_taxon USING btree (cd_ref);
