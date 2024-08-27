--Voici les données concernées pour cet export :
--• données ayant un statut (protégée et/ou menacée CR, EN, VU), de moins
--  de 20 ans, données précises (ni lieu-dit ni communale)
--• les données sensibles flore ne doivent pas être exclues de cet export ;
--  les données sensibles faune ne sont pas précises
--• les données privées à diffusion restreinte ne doivent pas être exclues
--  de cet export si surface de la ZH est < à 5x5km
--• toutes les autres données doivent être exclues

WITH
--liste des taxons protection nationale, régionale et cotation uicn cr, en, vu
liste_pn AS (
    SELECT DISTINCT cd_ref
    FROM (
        SELECT DISTINCT cd_ref
        FROM taxonomie.bdc_statut
        WHERE cd_type_statut = 'LRR'
            AND code_statut IN ('CR', 'EN', 'VU')
            AND lb_adm_tr IN ('Provence-Alpes-Côte-d''Azur')

        UNION

        SELECT DISTINCT cd_ref
        FROM taxonomie.bdc_statut
        WHERE lb_type_statut IN ('Protection nationale')
            AND lb_adm_tr IN ('France', 'France métropolitaine')

        UNION

        SELECT DISTINCT cd_ref
        FROM taxonomie.bdc_statut
        WHERE lb_type_statut IN ('Protection régionale')
            AND lb_adm_tr IN ('Provence-Alpes-Côte-d''Azur')
    ) AS table1
),
--liste des taxons en protection départementales
liste_pdep AS (
    SELECT DISTINCT
        cd_ref,
        lb_adm_tr,
        nom_valide_html
    FROM taxonomie.bdc_statut
    WHERE lb_type_statut IN ('Protection départementale')
        AND lb_adm_tr IN ('Alpes-Maritimes', 'Alpes-de-Haute-Provence', 'Bouches-du-Rhône', 'Hautes-Alpes', 'Var', 'Vaucluse')
),
--extraction pour les statuts nationaux et régionaux
obs_zh_pn AS (
    --extraction données sensibles flore ; les données sensibles faune sont toutes imprécises
    SELECT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref ,
        t.nom_valide,
        t.nom_vern ,
        z.code ,
        z.site
    FROM gn_synthese.synthese AS s
        JOIN ref_geo.sit_zones_humides_v2 AS z
            ON st_within(s.the_geom_local, z.geom)
        JOIN gn_synthese.cor_area_synthese cas ON
            s.id_synthese = cas.id_synthese
        JOIN ref_geo.l_areas l ON
            cas.id_area = l.id_area
        JOIN taxonomie.taxref t ON
            s.cd_nom = t.cd_nom
    WHERE t.cd_nom IN (SELECT cd_ref FROM liste_pn)
        AND s.additional_data @> '{"precisionLabel": "précis"}'
        AND date_part('year', date_max) >= date_part('year', NOW()) - 20
        AND s.id_nomenclature_sensitivity = 66
        -- avec données sensibles
        AND l.id_type = 26
        AND l.area_code IN ('04', '05', '06', '13', '83', '84')

    UNION

    --extraction des données Pr, NSP pour les ZH < 25 km² dont le niveau de diffusion n'est pas Précis
    SELECT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref ,
        t.nom_valide,
        t.nom_vern ,
        z.code ,
        z.site
    FROM gn_synthese.synthese s
        JOIN ref_geo.sit_zones_humides_v2 z ON
            st_within(s.the_geom_local,
            z.geom)
        JOIN gn_synthese.cor_area_synthese cas ON
            s.id_synthese = cas.id_synthese
        JOIN ref_geo.l_areas l ON
            cas.id_area = l.id_area
        JOIN taxonomie.taxref t ON
            s.cd_nom = t.cd_nom
        JOIN gn_meta.t_datasets d ON
            s.id_dataset = d.id_dataset
        JOIN ref_nomenclatures.t_nomenclatures n ON
            d.id_nomenclature_data_origin = n.id_nomenclature
    WHERE t.cd_nom IN (SELECT cd_ref FROM liste_pn)
        AND s.additional_data @> '{"precisionLabel": "précis"}'
        AND date_part('year', date_max) >= date_part('year', NOW()) - 20
        AND s.id_nomenclature_sensitivity != 66
        -- sauf données sensibles
        AND l.id_type = 26
        AND l.area_code IN ('04', '05', '06', '13', '83', '84')
        AND n.cd_nomenclature IN ('Pr', 'NSP')
        AND s.id_nomenclature_diffusion_level != 141
        --141 = niveau de diffusion précis
        AND z.surf_km2 < 25
),
obs_zh_pdep AS (
    --extraction pour les statuts départementaux
    --extraction données sensibles flore ; les données sensible s faune sont toutes imprécises
    SELECT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref ,
        t.nom_valide,
        t.nom_vern ,
        z.code ,
        z.site
    FROM
        gn_synthese.synthese s
    JOIN ref_geo.sit_zones_humides_v2 z ON
        st_within(s.the_geom_local,
        z.geom)
    JOIN gn_synthese.cor_area_synthese cas ON
        s.id_synthese = cas.id_synthese
    JOIN ref_geo.l_areas l ON
        cas.id_area = l.id_area
    JOIN taxonomie.taxref t ON
        s.cd_nom = t.cd_nom
    JOIN liste_pdep lp
        ON t.cd_nom = lp.cd_ref AND l.area_name = lp.lb_adm_tr
    WHERE s.additional_data@>'{"precisionLabel": "précis"}'
        AND date_part('year', date_max) >= date_part('year', NOW()) - 20
        AND s.id_nomenclature_sensitivity = 66
        -- avec données sensibles
        AND l.id_type = 26
        AND l.area_code IN ('04', '05', '06', '13', '83', '84')

    UNION

    --extraction des données Pr, NSP pour les ZH < 25 km² dont le niveau de diffusion n'est pas Précis
    SELECT
        s.id_synthese,
        s.date_max,
        s.observers,
        t.cd_ref ,
        t.nom_valide,
        t.nom_vern ,
        z.code ,
        z.site
    FROM gn_synthese.synthese s
        JOIN ref_geo.sit_zones_humides_v2 z
            ON st_within(s.the_geom_local, z.geom)
        JOIN gn_synthese.cor_area_synthese cas
            ON s.id_synthese = cas.id_synthese
        JOIN ref_geo.l_areas l
            ON cas.id_area = l.id_area
    JOIN taxonomie.taxref t ON
        s.cd_nom = t.cd_nom
    JOIN liste_pdep lp ON
        t.cd_nom = lp.cd_ref
            AND l.area_name = lp.lb_adm_tr
        JOIN gn_meta.t_datasets d ON
            s.id_dataset = d.id_dataset
        JOIN ref_nomenclatures.t_nomenclatures n ON
            d.id_nomenclature_data_origin = n.id_nomenclature
                WHERE
                    s.additional_data@>'{"precisionLabel": "précis"}'
                    AND date_part('year',
                    date_max)>= date_part('year',
                    now())-20
                        AND s.id_nomenclature_sensitivity != 66
                        -- sauf données sensibles
                        AND l.id_type = 26
                        AND l.area_code IN ('04', '05', '06', '13', '83', '84')
                            AND n.cd_nomenclature IN ('Pr', 'NSP')
                                AND s.id_nomenclature_diffusion_level != 141
                                --141 = niveau de diffusion précis
                                AND z.surf_km2 < 25
),
obs_zh AS (
    SELECT DISTINCT
        id_synthese,
        date_max,
        observers,
        cd_ref,
        nom_valide,
        nom_vern,
        code AS id_zh,
        "site"
    FROM (
            SELECT * FROM obs_zh_pdep
            UNION
            SELECT * FROM obs_zh_pn
        ) AS table3
)
SELECT
    id_zh,
    cd_ref,
    nom_valide,
    nom_vern,
    f_date::TIMESTAMP::DATE AS date_derobs,
    f_obs AS obs_derobs,
    count(*) AS nb_tot_obs
FROM (
        SELECT
            id_synthese,
            date_max,
            observers,
            cd_ref,
            nom_valide,
            nom_vern,
            id_zh,
            FIRST_VALUE(observers) OVER (
                PARTITION BY nom_valide, id_zh
                ORDER BY id_zh, nom_valide ASC, date_max DESC
            ) AS f_obs,
            FIRST_VALUE(date_max) OVER (
                PARTITION BY nom_valide, id_zh
                ORDER BY id_zh, nom_valide ASC, date_max DESC
            ) AS f_date
        FROM obs_zh
    ) AS table1
GROUP BY
    f_date,
    f_obs,
    cd_ref,
    nom_valide,
    nom_vern,
    id_zh
ORDER BY
    id_zh,
    nom_valide DESC

