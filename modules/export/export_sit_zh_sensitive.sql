--Voici les données concernées pour cet export :
--  • données précises (ni lieu-dit ni communale), ayant un statut de protection
--    national, régional ou départemental et/ou menacée (liste rouge  régionale CR, EN, VU),
--    de moins de 20 ans.
--  • les données sensibles floutées doivent être incluses dans cet export. Note :
--    les données sensibles faune ne sont pas précises et sont donc éliminée par le 1er critère.
--  • les données privées non sensibles floutées doivent être incluses
--    dans cet export si la surface de la ZH est < à 5x5km (25km²).
--  • toutes les autres données ne correspondant pas aux critères précédent doivent être excluses.
DROP MATERIALIZED VIEW IF EXISTS gn_exports.sit_zh_taxon_sensitive;

CREATE MATERIALIZED VIEW gn_exports.sit_zh_taxon_sensitive AS
WITH
-- Liste des taxons protection nationale, régionale et cotation UICN CR, EN, VU.
-- Valable pour toutes les observations car englobe toutes les données de la région.
nationally_protected_taxa AS (
    SELECT DISTINCT
        cd_ref
    FROM (
            SELECT DISTINCT
                tx.cd_ref
            FROM taxonomie.bdc_statut_text AS t
                JOIN taxonomie.bdc_statut_cor_text_values AS tv
                    ON tv.id_text = t.id_text
                JOIN taxonomie.bdc_statut_values AS v
                    ON v.id_value = tv.id_value
                JOIN taxonomie.bdc_statut_taxons AS tx
                    ON tx.id_value_text = tv.id_value_text
            WHERE t."enable" = TRUE
                AND t.cd_type_statut = 'LRR'
                AND v.code_statut IN ('CR', 'EN', 'VU')
            UNION
            SELECT DISTINCT
                tx.cd_ref
            FROM taxonomie.bdc_statut_text AS t
                JOIN taxonomie.bdc_statut_cor_text_values AS tv
                    ON tv.id_text = t.id_text
                JOIN taxonomie.bdc_statut_taxons AS tx
                    ON tx.id_value_text = tv.id_value_text
            WHERE t."enable" = TRUE
                AND t.cd_type_statut = 'PN' -- Protection nationale
            UNION
            SELECT DISTINCT
                tx.cd_ref
            FROM taxonomie.bdc_statut_text AS t
                JOIN taxonomie.bdc_statut_cor_text_values AS tv
                    ON tv.id_text = t.id_text
                JOIN taxonomie.bdc_statut_taxons AS tx
                    ON tx.id_value_text = tv.id_value_text
            WHERE t."enable" = TRUE
                AND t.cd_type_statut = 'PR' -- Protection régionale
        ) AS protected
),
-- Liste des taxons en protection départementales.
-- Valable uniquement si l'observation est dans le département de la protection.
departmentally_protected_taxa AS (
    SELECT DISTINCT
        tx.cd_ref,
        ta.id_area
    FROM taxonomie.bdc_statut_text AS t
        JOIN taxonomie.bdc_statut_cor_text_values AS tv
            ON tv.id_text = t.id_text
        JOIN taxonomie.bdc_statut_values AS v
            ON v.id_value = tv.id_value
        JOIN taxonomie.bdc_statut_taxons AS tx
            ON tx.id_value_text = tv.id_value_text
        JOIN taxonomie.bdc_statut_cor_text_area AS ta
            ON t.id_text = ta.id_text
    WHERE t."enable" = TRUE
        AND t.cd_type_statut = 'PD' -- Protection départementale
),
-- Extraction données sensibles (flore) et privées pour ZH de moins de 25km²
-- uniquement pour les statuts nationaux et régionaux
nationally_protected_observations_in_wetlands AS (
    SELECT DISTINCT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref,
        z.code
    FROM ref_geo.sit_zones_humides AS z
        JOIN gn_synthese.synthese AS s
            ON (
                s.the_geom_4326 && z.geom
                AND st_within(s.the_geom_4326, z.geom)
            )
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = s.cd_nom
        JOIN nationally_protected_taxa AS npt
            ON npt.cd_ref = t.cd_ref
    WHERE s.the_geom_4326 IS NOT NULL
        AND s.additional_data @> '{"precisionLabel": "précis"}'::jsonb
        AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
        -- uniquement données sensibles floutées
        AND s.id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')
        AND s.id_nomenclature_sensitivity IS NOT NULL

    UNION

    SELECT DISTINCT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref,
        z.code
    FROM ref_geo.sit_zones_humides AS z
        JOIN gn_synthese.synthese AS s
            ON (
                s.the_geom_4326 && z.geom
                AND st_within(s.the_geom_4326, z.geom)
            )
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = s.cd_nom
        JOIN nationally_protected_taxa AS npt
            ON npt.cd_ref = t.cd_ref
    WHERE s.the_geom_4326 IS NOT NULL
        AND s.additional_data @> '{"precisionLabel": "précis"}'::jsonb
        AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
        AND z.surf_m2::FLOAT < 25000000
        -- uniquement données NON sensibles
        AND (
            s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')
            OR s.id_nomenclature_sensitivity IS NULL
        )
        -- uniquement données privées floutées
        AND s.id_nomenclature_diffusion_level != ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5')
        AND s.id_nomenclature_diffusion_level IS NOT NULL
),
-- Extraction données sensibles (flore) et privées pour ZH de moins de 25km²
-- uniquement pour les statuts départementaux
departmentally_protected_observations_in_wetlands AS (
    SELECT DISTINCT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref,
        z.code
    FROM ref_geo.sit_zones_humides AS z
        JOIN gn_synthese.synthese AS s
            ON (
                s.the_geom_4326 && z.geom
                AND st_within(s.the_geom_4326, z.geom)
            )
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = s.cd_nom
        JOIN gn_synthese.cor_area_synthese AS csa
            ON csa.id_synthese = s.id_synthese
        JOIN departmentally_protected_taxa AS dpt
            ON (
                dpt.cd_ref = t.cd_ref
                AND dpt.id_area = csa.id_area
            )
    WHERE s.the_geom_4326 IS NOT NULL
        AND s.additional_data @> '{"precisionLabel": "précis"}'
        AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
        -- uniquement données sensibles floutées
        AND s.id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature ('SENSIBILITE', '0')
        AND s.id_nomenclature_sensitivity IS NOT NULL

    UNION

    SELECT DISTINCT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref,
        z.code
    FROM ref_geo.sit_zones_humides AS z
        JOIN gn_synthese.synthese AS s
            ON (
                s.the_geom_4326 && z.geom
                AND st_within(s.the_geom_4326, z.geom)
            )
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = s.cd_nom
        JOIN gn_synthese.cor_area_synthese AS csa
            ON csa.id_synthese = s.id_synthese
        JOIN departmentally_protected_taxa AS dpt
            ON (
                dpt.cd_ref = t.cd_ref
                AND dpt.id_area = csa.id_area
            )
    WHERE s.the_geom_4326 IS NOT NULL
        AND s.additional_data @> '{"precisionLabel": "précis"}'
        AND DATE_PART('year', s.date_max) >= DATE_PART('year', NOW()) - 20
        AND z.surf_m2::FLOAT < 25000000
        -- uniquement données NON sensibles
        AND (
            s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')
            OR s.id_nomenclature_sensitivity IS NULL
        )
        -- uniquement données privées floutées
        AND s.id_nomenclature_diffusion_level != ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5')
        AND s.id_nomenclature_diffusion_level IS NOT NULL
),
sensitive_observations_in_wetlands AS (
    SELECT DISTINCT
        o.id_synthese,
        o.date_max,
        o.observers,
        o.cd_ref,
        t.nom_complet,
        t.nom_vern,
        o.code AS id_zh
    FROM (
            SELECT * FROM departmentally_protected_observations_in_wetlands
            UNION
            SELECT * FROM nationally_protected_observations_in_wetlands
        ) AS o
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = o.cd_ref
)
SELECT
    id_zh,
    cd_ref,
    nom_complet,
    nom_vern,
    last_observation_date::TIMESTAMP::DATE AS date_derobs,
    last_observation_observers AS obs_derobs,
    COUNT(*) AS nb_tot_obs
FROM (
        SELECT
            id_synthese,
            date_max,
            observers,
            cd_ref,
            nom_complet,
            nom_vern,
            id_zh,
            FIRST_VALUE(date_max) OVER (
                PARTITION BY nom_complet, id_zh
                ORDER BY id_zh, nom_complet ASC, date_max DESC
            ) AS last_observation_date,
            FIRST_VALUE(observers) OVER (
                PARTITION BY nom_complet, id_zh
                ORDER BY id_zh, nom_complet ASC, date_max DESC
            ) AS last_observation_observers
        FROM sensitive_observations_in_wetlands
    ) AS observations
GROUP BY id_zh, cd_ref, nom_complet, nom_vern, last_observation_date, last_observation_observers
ORDER BY id_zh, nom_complet DESC
WITH
    DATA;

CREATE UNIQUE INDEX sit_zh_taxon_sensitive_pk ON gn_exports.sit_zh_taxon_sensitive USING btree (id_zh, cd_ref);

CREATE INDEX sit_zh_taxon_sensitive_cd_ref_idx ON gn_exports.sit_zh_taxon_sensitive USING btree (cd_ref);
