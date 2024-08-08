-- Query to extracts datasets for SINP
-- Usage (from local computer): cat ./inpn_export_acquisition_frameworks.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_inpn_af_extracts.csv
COPY (
    WITH ca_utilises AS (
        SELECT
            DISTINCT jd.id_acquisition_framework
        FROM
            (
                SELECT
                    DISTINCT id_dataset
                FROM
                    gn_synthese.synthese
            ) AS t
            JOIN gn_meta.t_datasets AS jd ON t.id_dataset = jd.id_dataset
        WHERE jd.dataset_name not ilike '%mnhn%'
    ),
    acteur_principal AS (
        SELECT
            id_acquisition_framework,
            (
                SELECT
                    row_to_json(_)
                FROM
                    (
                        SELECT
                            organisme,
                            "RoleActeurValue"
                    ) AS _
            ) AS acteurprincipal
        FROM
            (
                SELECT
                    a.id_acquisition_framework,
                    o.nom_organisme AS organisme,
                    n.mnemonique AS "RoleActeurValue"
                FROM
                    gn_meta.cor_acquisition_framework_actor AS a
                    LEFT JOIN utilisateurs.bib_organismes AS o ON a.id_organism = o.id_organisme
                    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n ON n.id_nomenclature = a.id_nomenclature_actor_role
                WHERE
                    n.mnemonique = 'Contact principal'
                    AND a.id_organism IS NOT NULL
            ) AS role_main_actor
    ),
    acteur_autre AS (
        SELECT
            id_acquisition_framework,
            (
                SELECT
                    row_to_json(_)
                FROM
                    (
                        SELECT
                            organisme,
                            "RoleActeurValue",
                            "nomPrenom",
                            mail
                    ) AS _
            ) AS acteur
        FROM
            (
                SELECT
                    a.id_acquisition_framework,
                    o.nom_organisme AS organisme,
                    n.mnemonique AS "RoleActeurValue",
                    NULL AS "nomPrenom",
                    NULL AS mail
                FROM
                    gn_meta.cor_acquisition_framework_actor AS a
                    LEFT JOIN utilisateurs.bib_organismes AS o ON a.id_organism = o.id_organisme
                    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n ON n.id_nomenclature = a.id_nomenclature_actor_role
                WHERE
                    n.mnemonique != 'Contact principal'
                    AND a.id_organism IS NOT NULL
                UNION
                SELECT
                    ca.id_acquisition_framework,
                    o.nom_organisme AS organisme,
                    n.label_default AS "roleActeur",
                    r.nom_role || ' ' || r.prenom_role AS "nomPrenom",
                    r.email AS mail
                FROM
                    gn_meta.cor_acquisition_framework_actor AS ca
                    JOIN utilisateurs.t_roles AS r ON ca.id_role = r.id_role
                    JOIN utilisateurs.bib_organismes AS o ON r.id_organisme = o.id_organisme
                    JOIN ref_nomenclatures.t_nomenclatures n ON ca.id_nomenclature_actor_role = n.id_nomenclature
                WHERE
                    ca.id_role IS NOT NULL
                    AND n.mnemonique != 'Contact principal'
            ) AS role_oganism_other_actors
    ),
    acteur_autre_agg AS (
        SELECT
            id_acquisition_framework,
            json_agg(acteur) AS acteurautre
        FROM
            acteur_autre
        GROUP BY
            id_acquisition_framework
    )
    SELECT
        --ca.id_acquisition_framework AS id_ca,
        ca.acquisition_framework_name AS libelle,
        n4.label_default AS "voletSINP",
        n1.label_default AS objectif,
        ca.acquisition_framework_desc AS description,
        ca.unique_acquisition_framework_id AS "identifiantCadre",
        --ca.id_nomenclature_territorial_level,
        n3.label_default AS "niveauTerritorial",
        'Métropole' AS territoire,
        ca.territory_desc AS "precisionGeographique",
        ca.keywords AS "motCle",
        --ca.id_nomenclature_financing_type,
        n2.label_default AS "typeFinancement",
        ap.acteurprincipal AS "acteurPrincipal",
        aa.acteurautre AS "acteurAutre",
        ca.meta_create_date :: TIMESTAMP :: DATE AS "dateCreationMtd",
        ca.meta_update_date :: TIMESTAMP :: DATE AS "dateMiseAJourMtd",
        ca.target_description AS "descriptionCible",
        ca.ecologic_or_geologic_target AS "cibleEcologiqueOuGeologique",
        ca2.unique_acquisition_framework_id AS "idMetaCadreParent",
        ca.is_parent AS "estMetaCadre",
        --ca.opened,
        --ca.id_digitizer,
        ca.acquisition_framework_start_date AS "dateLancement",
        ca.acquisition_framework_end_date AS "dateCloture" --ca.initial_closing_date
    FROM
        gn_meta.t_acquisition_frameworks AS ca
        LEFT JOIN gn_meta.cor_acquisition_framework_objectif AS cao ON ca.id_acquisition_framework = cao.id_acquisition_framework
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n1 ON cao.id_nomenclature_objectif = n1.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n2 ON ca.id_nomenclature_financing_type = n2.id_nomenclature
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n3 ON ca.id_nomenclature_territorial_level = n3.id_nomenclature
        LEFT JOIN gn_meta.cor_acquisition_framework_voletsinp AS vs ON ca.id_acquisition_framework = vs.id_acquisition_framework
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS n4 ON vs.id_nomenclature_voletsinp = n4.id_nomenclature
        LEFT JOIN acteur_principal AS ap ON ca.id_acquisition_framework = ap.id_acquisition_framework
        LEFT JOIN acteur_autre_agg AS aa ON ca.id_acquisition_framework = aa.id_acquisition_framework
        LEFT JOIN gn_meta.t_acquisition_frameworks AS ca2 ON ca.acquisition_framework_parent_id = ca2.id_acquisition_framework
    WHERE
        ca.id_acquisition_framework IN (
            SELECT
                id_acquisition_framework
            FROM
                ca_utilises
        )
) TO stdout WITH (format csv, header, delimiter E'\t', null '\N');
