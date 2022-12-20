-- Query to extracts datasets for SINP
-- Usage (from local computer): cat ./inpn_export_datasets.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql --no-psqlrc -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_inpn_dataset_extracts.csv

COPY (
    WITH jdd_utilises AS (
        SELECT
            DISTINCT s.id_dataset,
            d.unique_dataset_id
        FROM
            gn_synthese.synthese AS s
            JOIN gn_meta.t_datasets AS d ON s.id_dataset = d.id_dataset
    ),
    objet_loc AS (
        SELECT
            id_synthese,
            id_dataset,
            the_geom_4326 AS geom
        FROM
            gn_synthese.synthese
        WHERE
            the_geom_4326 IS NOT NULL
    ),
    box_jdd AS (
        SELECT
            id_dataset,
            st_xmin(st_extent(geom)) AS borneOuest,
            st_xmax(st_extent(geom)) AS borneEst,
            st_ymin(st_extent(geom)) AS borneSud,
            st_ymax(st_extent(geom)) AS borneNord
        FROM
            objet_loc
        GROUP BY
            id_dataset
    ),
    contact_principal AS (
        SELECT
            id_dataset,
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
                    cda.id_dataset,
                    o.nom_organisme AS organisme,
                    n.mnemonique AS "RoleActeurValue"
                FROM
                    gn_meta.cor_dataset_actor AS cda
                    JOIN utilisateurs.t_roles AS r ON cda.id_role = r.id_role
                    JOIN utilisateurs.bib_organismes AS o ON r.id_organisme = o.id_organisme
                    JOIN ref_nomenclatures.t_nomenclatures AS n ON cda.id_nomenclature_actor_role = n.id_nomenclature
                WHERE
                    n.mnemonique = 'Contact principal'
            ) AS role_main_actor
    ),
    acteur_autre AS (
        SELECT
            id_dataset,
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
                    a.id_dataset,
                    o.nom_organisme AS organisme,
                    n.mnemonique AS "RoleActeurValue",
                    NULL AS "nomPrenom",
                    NULL AS mail
                FROM
                    gn_meta.cor_dataset_actor AS a
                    LEFT JOIN utilisateurs.bib_organismes AS o ON a.id_organism = o.id_organisme
                    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n ON n.id_nomenclature = a.id_nomenclature_actor_role
                WHERE
                    a.id_organism IS NOT NULL
                UNION
                SELECT
                    a.id_dataset,
                    o.nom_organisme AS organisme,
                    n.label_default AS "roleActeur",
                    r.nom_role || ' ' || r.prenom_role AS "nomPrenom",
                    r.email AS mail
                FROM
                    gn_meta.cor_dataset_actor AS a
                    JOIN utilisateurs.t_roles r ON a.id_role = r.id_role
                    JOIN utilisateurs.bib_organismes o ON r.id_organisme = o.id_organisme
                    JOIN ref_nomenclatures.t_nomenclatures n ON a.id_nomenclature_actor_role = n.id_nomenclature
                WHERE
                    a.id_role IS NOT NULL
            ) AS table1
    ),
    acteur_autre_agg AS (
        SELECT
            id_dataset,
            json_agg(acteur) AS pointcontactjdd
        FROM
            acteur_autre
        GROUP BY
            id_dataset
    )
    SELECT
        --jdd.id_dataset,
        jdd.dataset_name AS libelle,
        jdd.dataset_shortname AS "libelleCourt",
        jdd.dataset_desc AS description,
        jdd.meta_create_date :: TIMESTAMP :: DATE AS "dateCreation",
        jdd.meta_update_date :: TIMESTAMP :: DATE AS "dateRevision",
        n1.label_default AS "typeDonnees",
        jdd.unique_dataset_id AS "identifiantJdd",
        aa.pointcontactjdd AS "pointContactJdd",
        jdd.keywords AS "motCle",
        n7.label_default AS territoire,
        jdd.marine_domain AS "domaineMarin",
        jdd.terrestrial_domain AS "domaineTerrestre",
        ca.unique_acquisition_framework_id AS "identifiantCadre",
        n2.label_default AS "objectifJdd",
        --jdd.bbox_west,
        --jdd.bbox_east,
        --jdd.bbox_south,
        --jdd.bbox_north,
        bj.borneOuest,
        bj.borneEst,
        bj.borneSud,
        bj.borneNord,
        n3.label_default AS "methodeRecueil",
        --cp.acteurprincipal AS "pointContactPF"
        '{"organisme":"CEN PACA","RoleActeurValue":"Contact principal","nomPrenom":"Chauvin Hélène","mail":"helene.chauvin@cen-paca.org"}' AS "pointContactPF" --jdd.id_nomenclature_data_origin,
        --n4.label_default as "origine", --absent du standard
        --jdd.id_nomenclature_source_status,
        --n5 .label_default as "source", --absent du standard
        --jdd.id_nomenclature_resource_type,
        --n6 .label_default as "resource", --absent du standard
        --jdd.active,
        --jdd.validable,
        --jdd.id_digitizer,
        --jdd.id_taxa_list
    FROM
        gn_meta.t_datasets jdd
        JOIN ref_nomenclatures.t_nomenclatures AS n1 ON jdd.id_nomenclature_data_type = n1.id_nomenclature
        JOIN ref_nomenclatures.t_nomenclatures AS n2 ON jdd.id_nomenclature_dataset_objectif = n2.id_nomenclature
        JOIN ref_nomenclatures.t_nomenclatures AS n3 ON jdd.id_nomenclature_collecting_method = n3.id_nomenclature --join ref_nomenclatures.t_nomenclatures n4 on jdd.id_nomenclature_data_origin  = n4.id_nomenclature
        --join ref_nomenclatures.t_nomenclatures n5 on jdd.id_nomenclature_source_status  = n5.id_nomenclature
        --join ref_nomenclatures.t_nomenclatures n6 on jdd.id_nomenclature_resource_type  = n6.id_nomenclature
        LEFT JOIN box_jdd AS bj ON jdd.id_dataset = bj.id_dataset
        LEFT JOIN gn_meta.cor_dataset_territory AS ct ON jdd.id_dataset = ct.id_dataset
        JOIN ref_nomenclatures.t_nomenclatures AS n7 ON ct.id_nomenclature_territory = n7.id_nomenclature
        LEFT JOIN gn_meta.t_acquisition_frameworks AS ca ON jdd.id_acquisition_framework = ca.id_acquisition_framework
        LEFT JOIN contact_principal AS cp ON jdd.id_dataset = cp.id_dataset
        LEFT JOIN acteur_autre_agg AS aa ON jdd.id_dataset = aa.id_dataset
    WHERE
        jdd.id_dataset IN (
            SELECT
                id_dataset
            FROM
                jdd_utilises
        )
) TO stdout WITH (format csv, header, delimiter E'\t');
