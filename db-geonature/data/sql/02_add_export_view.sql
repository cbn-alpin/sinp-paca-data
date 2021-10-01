-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Add new view for Export module.
-- Transfert this script on server this way:
-- rsync -av ./02_* geonat@db-paca-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/02_*
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_exports.v_synthese_sinp_22362d470380'
DROP VIEW IF EXISTS gn_exports.v_synthese_sinp_22362d470380 ;

CREATE OR REPLACE VIEW gn_exports.v_synthese_sinp_22362d470380 AS
    WITH cda AS (
        SELECT td.id_dataset,
            td.id_acquisition_framework,
            td.unique_dataset_id,
            td.dataset_name,
            td.id_nomenclature_data_origin,
            string_agg(DISTINCT bo.nom_organisme::text, ' | '::text) AS acteurs
        FROM gn_meta.t_datasets AS td
            LEFT JOIN gn_meta.cor_dataset_actor AS cad
                ON cad.id_dataset = td.id_dataset
            LEFT JOIN ref_nomenclatures.t_nomenclatures nomencl
                ON nomencl.id_nomenclature = cad.id_nomenclature_actor_role
            LEFT JOIN utilisateurs.bib_organismes bo
                ON bo.id_organisme = cad.id_organism
        WHERE nomencl.cd_nomenclature = '1'
        GROUP BY td.id_dataset
    ),
    areas AS (
        SELECT ta.id_type,
            ta.type_code,
            ta.ref_version,
            a_1.id_area,
            a_1.area_code,
            a_1.area_name
        FROM ref_geo.bib_areas_types ta
            JOIN ref_geo.l_areas a_1 ON ta.id_type = a_1.id_type
        WHERE ta.type_code::text = ANY (ARRAY['DEP'::character varying, 'COM'::character varying, 'M10'::character varying]::text[])
    )
    SELECT s.id_synthese AS "ID_synthese",
        s.entity_source_pk_value AS "idOrigine",
        s.unique_id_sinp AS "idSINPOccTax",
        s.unique_id_sinp_grp AS "idSINPRegroupement",
        cda.unique_dataset_id AS "idSINPJdd",
        s.date_min::date AS "dateDebut",
        s.date_min::time without time zone AS "heureDebut",
        s.date_max::date AS "dateFin",
        s.date_max::time without time zone AS "heureFin",
        t.cd_nom AS "cdNom",
        t.cd_ref AS "codeHabRef",
        h.cd_hab AS habitat,
        h.lb_code AS "codeHabitat",
        'Habref 5.0 2019'::text AS "versionRef",
        cda.acteurs AS "organismeGestionnaireDonnee",
        a.jname ->> 'DEP'::text AS "nomDepartement",
        a.jcode ->> 'DEP'::text AS "codeDepartement",
        a.jversion ->> 'DEP'::text AS "anneeRefDepartement",
        a.jname ->> 'COM'::text AS "nomCommune",
        a.jcode ->> 'COM'::text AS "codeCommune",
        a.jversion ->> 'COM'::text AS "anneeRefCommune",
        a.jcode ->> 'M10'::text AS "codeMaille",
        s.nom_cite AS "nomCite",
        s.count_min AS "denombrementMin",
        s.count_max AS "denombrementMax",
        s.altitude_min AS "altitudeMin",
        s.altitude_max AS "altitudeMax",
        (s.altitude_min + s.altitude_max) / 2 AS "altitudeMoyenne",
        s.depth_min AS "profondeurMin",
        s.depth_max AS "profondeurMax",
        (s.depth_max - s.depth_min) / 2 AS "profondeurMoyenne",
        s.observers AS observateur,
        s.determiner AS determinateur,
        s.digital_proof AS "uRLPreuveNumerique",
        s.non_digital_proof AS "preuveNonNumerique",
        s.the_geom_4326 AS geometrie,
        s."precision" AS "precisionGeometrie",
        s.place_name AS "nomLieu",
        s.comment_context AS commentaire,
        s.comment_description AS "obsDescription",
        s.meta_create_date AS "dateDetermination",
        s.meta_update_date AS "dEEDateTransformation",
        COALESCE(s.meta_update_date, s.meta_create_date) AS "dEEDateDerniereModification",
        s.reference_biblio AS "referenceBiblio",
        ss.attribution_date AS "sensiDateAttribution",
        n1.label_default AS "natureObjetGeo",
        n2.label_default AS "methodeRegroupement",
        n4.label_default AS "obsTechnique",
        n5.label_default AS "occStatutBiologique",
        n6.label_default AS "occEtatBiologique",
        n7.label_default AS "occNaturalite",
        n8.label_default AS "preuveExistante",
        n9.label_default AS "diffusionNiveauPrecision",
        n10.label_default AS "occStadeDeVie",
        n11.label_default AS "occSexe",
        n12.label_default AS "objetDenombrement",
        n13.label_default AS "typeDenombrement",
        n14.label_default AS "sensiNiveau",
        n15.label_default AS "statutObservation",
        n16.label_default AS "dEEFloutage",
        n17.label_default AS "statutSource",
        n19.label_default AS "occMethodeDetermination",
        n20.label_default AS "occComportement",
        n21.label_default AS "dSPublique"
    FROM gn_synthese.synthese s
        JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
        LEFT JOIN LATERAL (
            SELECT
                d_1.id_synthese,
                json_object_agg(d_1.type_code, d_1.o_name) AS jname,
                json_object_agg(d_1.type_code, d_1.o_code) AS jcode,
                json_object_agg(d_1.type_code, d_1.ref_version) AS jversion
            FROM (
                SELECT sa.id_synthese,
                    ta.type_code,
                    string_agg(ta.area_name::text, '|'::text) AS o_name,
                    string_agg(ta.area_code::text, '|'::text) AS o_code,
                    string_agg(ta.ref_version::character varying::text, '|'::text) AS ref_version
                FROM gn_synthese.cor_area_synthese sa
                    JOIN areas ta ON ta.id_area = sa.id_area
                WHERE sa.id_synthese = s.id_synthese
                GROUP BY sa.id_synthese, ta.type_code
            ) AS d_1
            GROUP BY d_1.id_synthese
        ) a ON TRUE
        LEFT JOIN LATERAL (
            SELECT css.meta_create_date AS attribution_date
            FROM gn_sensitivity.cor_sensitivity_synthese AS css
            WHERE css.uuid_attached_row = s.unique_id_sinp
            ORDER BY css.meta_create_date DESC
            LIMIT 1
        ) AS ss ON TRUE
        LEFT JOIN cda ON cda.id_dataset = s.id_dataset
        LEFT JOIN ref_habitats.habref h ON h.cd_hab = s.cd_hab
        LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n4 ON s.id_nomenclature_obs_technique = n4.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON cda.id_nomenclature_data_origin = n21.id_nomenclature
    WHERE cda.unique_dataset_id IN ('0d95da9e-03e5-4ac8-a49a-22362d470380'::uuid);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
