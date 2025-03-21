-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Restore "gn_synthese.v_synthese_for_export" with SINP PACA specificity.
-- See : https://github.com/cbn-alpin/sinp-paca-tickets/issues/70#issuecomment-889976081
-- Transfert this script on server this way:
-- rsync -av ./01_fix_v_synthese_for_export.sql geonat@db-paca-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/01_fix_v_synthese_for_export.sql
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_synthese.v_synthese_for_export with new fields see ticket #70'
-- Ajout des colonnes id_nomenclature_sensitivity et id_nomenclature_diffusion_level (obligatoires)
-- Suppression de toutes les colonnes inutiles
DROP VIEW IF EXISTS gn_synthese.v_synthese_for_export ;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
    SELECT s.id_synthese,
        s.unique_id_sinp AS uuid_perm_sinp,
        s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
        sd.dataset_name AS jdd_nom,
        sd.unique_dataset_id AS jdd_uuid,
        sd.organisms AS fournisseur,
        s.observers AS observateurs,
        t.cd_ref,
        t.nom_valide,
        t.nom_vern AS nom_vernaculaire,
        t.classe AS classe,
        t.famille AS famille,
        t.ordre AS ordre,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::date AS date_debut,
        s.date_max::date AS date_fin,
        st_asgeojson(s.the_geom_4326) AS geojson_4326, -- Use for SHP export and data blurring
        st_x(st_transform(st_centroid(s.the_geom_point), 4326)) AS x_centroid_4326,
        st_y(st_transform(st_centroid(s.the_geom_point), 4326)) AS y_centroid_4326,
        s."precision" AS precision_geographique,
        s.additional_data ->> 'precisionLabel' AS type_precision,
        sa.communes,
        s.altitude_min AS alti_min,
        n3.label_default AS technique_observation,
        n10.label_default AS stade_vie,
        n5.label_default AS statut_biologique,
        n11.label_default AS sexe,
        n20.label_default AS comportement,
        n17.label_default AS type_source,
        CASE
            WHEN ns.cd_nomenclature = '0' THEN 'donnée non sensible'
            WHEN s.id_nomenclature_sensitivity IS NULL THEN ''
            ELSE 'donnée sensible'
        END AS sensibilite,
        CASE
            WHEN s.additional_data ->> 'confidential' = 'true' THEN 'donnée confidentielle'
            ELSE 'donnée non confidentielle'
        END AS confidentialite,
        -- Fields use in internal
        sd.id_dataset AS jdd_id, -- Use for CRUVED
        s.id_digitiser AS id_digitiser, -- Use for CRUVED
        st_asgeojson(s.the_geom_local) AS geojson_local, -- Use for SHP export
        s.id_nomenclature_sensitivity, -- Use for data blurring
        s.id_nomenclature_diffusion_level -- Use for data blurring
    FROM gn_synthese.synthese AS s
        JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
        LEFT JOIN LATERAL (
            SELECT
                cas.id_synthese,
                string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
            FROM gn_synthese.cor_area_synthese AS cas
                JOIN ref_geo.l_areas AS a_1
                    ON cas.id_area = a_1.id_area
                JOIN ref_geo.bib_areas_types AS ta
                    ON ta.id_type = a_1.id_type AND ta.type_code::text = 'COM'::text
            WHERE cas.id_synthese = s.id_synthese
            GROUP BY cas.id_synthese
        ) AS sa ON true
        LEFT JOIN LATERAL (
            SELECT
                td.id_dataset,
                td.dataset_name,
                td.unique_dataset_id,
                string_agg(DISTINCT bo.nom_organisme::text, ', '::text) AS organisms
            FROM gn_meta.t_datasets AS td
                 LEFT JOIN gn_meta.cor_dataset_actor cad
                    ON (
                        cad.id_dataset = td.id_dataset
                        AND (
                            cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '5'::character varying)
                            OR cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '6'::character varying)
                        )
                    )
                 LEFT JOIN utilisateurs.bib_organismes bo
                    ON bo.id_organisme = cad.id_organism
            WHERE td.id_dataset = s.id_dataset
            GROUP BY td.id_dataset
        ) sd ON true
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11 ON s.id_nomenclature_sex = n11.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS ns ON s.id_nomenclature_sensitivity = ns.id_nomenclature ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
