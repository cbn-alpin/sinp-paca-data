-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Restore "gn_synthese.v_synthese_for_export" with SINP PACA specificity.
-- See : https://github.com/cbn-alpin/sinp-paca-tickets/issues/70#issuecomment-889976081
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/01_fix_v_synthese_for_export.sql
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_synthese.v_synthese_for_export with new fields see ticket #70'
-- Ajout des colonnes id_nomenclature_sensitivity et id_nomenclature_diffusion_level (obligatoires)
-- Suppression de toutes les colonnes inutiles
DROP VIEW gn_synthese.v_synthese_for_export ;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
    SELECT s.id_synthese,
        s.unique_id_sinp AS uuid_perm_sinp,
        s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
        d.dataset_name AS jdd_nom,
        d.unique_dataset_id AS jdd_uuid,
        n21.label_default AS niveau_validation,
        s.validator AS validateur,
        s.observers AS observateurs,
        s.determiner AS determinateur,
        t.cd_ref,
        t.nom_valide,
        t.nom_vern as nom_vernaculaire,
        t.regne AS regne,
        t.classe AS classe,
        t.ordre AS ordre,
        t.famille AS famille,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::date AS date_debut,
        s.date_max::date AS date_fin,
        public.st_asgeojson(s.the_geom_4326) AS geojson_4326,-- Use for SHP export and data blurring
        st_x(st_transform(st_centroid(s.the_geom_point), 4326)) AS x_centroid_4326,
        st_y(st_transform(st_centroid(s.the_geom_point), 4326)) AS y_centroid_4326,
        s."precision" AS precision_geographique,
        n1.label_default AS nature_objet_geo,
        communes AS communes,
        s.altitude_min AS alti_min,
        n3.label_default AS technique_observation,
        n10.label_default AS stade_vie,
        n5.label_default AS biologique_statut,
        n11.label_default AS sexe,
        n20.label_default AS comportement,
        n17.label_default AS statut_source,
        s.reference_biblio AS reference_biblio,
        -- Fields use in internal
        d.id_dataset AS jdd_id, -- Use for CRUVED
        s.id_digitiser AS id_digitiser, -- Use for CRUVED
        public.ST_asgeojson(s.the_geom_local) AS geojson_local,-- Use for SHP export
        s.id_nomenclature_sensitivity, -- Use for data blurring
        s.id_nomenclature_diffusion_level -- Use for data blurring
    FROM gn_synthese.synthese AS s
        JOIN taxonomie.taxref AS t ON t.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets AS d ON d.id_dataset = s.id_dataset
        LEFT JOIN LATERAL (
            SELECT id_synthese, string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
            FROM gn_synthese.cor_area_synthese cas
                JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
                JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code ='COM'
            WHERE cas.id_synthese = s.id_synthese
            GROUP BY id_synthese
        ) sa ON true
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11 ON s.id_nomenclature_sex = n11.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
