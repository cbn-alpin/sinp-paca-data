-- Query to extracts observations for Bouches-du-Rhône (13) with sensitive data !
-- Usage (from local computer): cat ./dep13_observations.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_observations_dep13.csv
-- The CSV file should contain:  lines.
COPY (
    WITH cda AS (
        -- ATTENTION : pas de récupération de l'organisme d'un utilisateur lié.
        SELECT
            d.id_dataset,
            string_agg(DISTINCT o.nom_organisme, ', ') AS acteurs
        FROM gn_meta.t_datasets AS d
            JOIN gn_meta.cor_dataset_actor AS da
                ON da.id_dataset = d.id_dataset
            JOIN utilisateurs.bib_organismes AS o
                ON o.id_organisme = da.id_organism
        GROUP BY
            d.id_dataset
    )
    SELECT
        -- Sujet observation
        s.unique_id_sinp AS "idSINPOccTax",
        n15.label_default AS "statutObservation",
        s.nom_cite AS "nomCite",
        s.the_geom_local AS "geometrie",
        n1.label_default AS "natureObjetGeo",
        s.precision AS "precisionGeometrie",
        s.place_name AS "nomLieu",
        s.date_min :: date AS "dateDebut",
        s.date_min :: time WITHOUT time ZONE AS "heureDebut",
        s.date_max :: date AS "dateFin",
        s.date_max :: time WITHOUT time ZONE AS "heureFin",
        t.cd_nom AS "cdNom",
        s.determiner AS determinateur,
        s.meta_create_date AS "dateDetermination",
        s.altitude_min AS "altitudeMin",
        (s.altitude_min + s.altitude_max) / 2 AS "altitudeMoyenne",
        s.altitude_max AS "altitudeMax",
        s.count_min AS "denombrementMin",
        s.count_max AS "denombrementMax",
        s.depth_min AS "profondeurMin",
        (s.depth_max - s.depth_min) / 2 AS "profondeurMoyenne",
        s.depth_max AS "profondeurMax",
        s.observers AS observateur,
        s.comment_context AS commentaire,
        -- Source
        COALESCE(s.meta_update_date, s.meta_create_date) AS "dEEDateDerniereModification",
        s.meta_update_date AS "dEEDateTransformation",
        n16.label_default AS "dEEFloutage",
        n9.label_default AS "diffusionNiveauPrecision",
        n21.label_default AS "dSPublique",
        s.entity_source_pk_value AS "idOrigine",
        d.unique_dataset_id AS "idSINPJdd",
        cda.acteurs AS "organismeGestionnaireDonnee",
        -- orgTransformation = CBNA voir avec Ornella
        s.reference_biblio AS "referenceBiblio",
        NULL AS "sensiDateAttribution",
        n14.label_default AS "sensiNiveau",
        n17.label_default AS "statutSource",
        -- Descriptif sujet
        s.comment_description AS "obsDescription",
        n4.label_default AS "obsTechnique",
        n6.label_default AS "occEtatBiologique",
        n19.label_default AS "occMethodeDetermination",
        n7.label_default AS "occNaturalite",
        n11.label_default AS "occSexe",
        n10.label_default AS "occStadeDeVie",
        n5.label_default AS "occStatutBiologique",
        n8.label_default AS "preuveExistante",
        s.digital_proof AS "uRLPreuveNumerique",
        s.non_digital_proof AS "preuveNonNumerique",
        n20.label_default AS "occComportement",
        -- Regroupement observations
        s.unique_id_sinp_grp AS "idSINPRegroupement",
        s.grp_method AS "methodeRegroupement",
        n2.label_default AS "typeRegroupement",
        n12.label_default AS "objetDenombrement",
        n13.label_default AS "typeDenombrement"
    FROM gn_synthese.synthese AS s
        JOIN gn_synthese.cor_area_synthese AS cas
            ON s.id_synthese = cas.id_synthese
        JOIN taxonomie.taxref AS t
            ON t.cd_nom = s.cd_nom
        JOIN gn_meta.t_datasets AS d
            ON d.id_dataset = s.id_dataset
        JOIN gn_meta.t_acquisition_frameworks AS af
            ON d.id_acquisition_framework = af.id_acquisition_framework
        JOIN gn_synthese.t_sources AS sources
            ON sources.id_source = s.id_source
        LEFT JOIN cda
            ON d.id_dataset = cda.id_dataset
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n1
            ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n2
            ON s.id_nomenclature_grp_typ = n2.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n4
            ON s.id_nomenclature_obs_technique = n4.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5
            ON s.id_nomenclature_bio_status = n5.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n6
            ON s.id_nomenclature_bio_condition = n6.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n7
            ON s.id_nomenclature_naturalness = n7.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n8
            ON s.id_nomenclature_exist_proof = n8.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n9
            ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10
            ON s.id_nomenclature_life_stage = n10.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11
            ON s.id_nomenclature_sex = n11.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n12
            ON s.id_nomenclature_obj_count = n12.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n13
            ON s.id_nomenclature_type_count = n13.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n14
            ON s.id_nomenclature_sensitivity = n14.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n15
            ON s.id_nomenclature_observation_status = n15.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n16
            ON s.id_nomenclature_blurring = n16.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17
            ON s.id_nomenclature_source_status = n17.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n18
            ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n19
            ON s.id_nomenclature_determination_method = n19.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20
            ON s.id_nomenclature_behaviour = n20.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n21
            ON d.id_nomenclature_data_origin = n21.id_nomenclature
    WHERE cas.id_area = (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE area_code = '13'
            AND id_type = ref_geo.get_id_area_type_by_code('DEP')
    )
) TO stdout
WITH (format csv, header, delimiter E'\t');
