-- Script to export observations counts by organisms (productor or provider)
-- Usage (from local computer): cat ./observations_count_by_organisms.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_organisms.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH datasets_by_organism AS (
        SELECT DISTINCT
            COALESCE(o.nom_organisme, '-- Non renseigné --') AS organism_name,
            organisms[1] AS organism_uuid,
            array_agg(id_dataset ORDER BY id_dataset ASC) AS datasets_ids
        FROM (
            SELECT DISTINCT d.id_dataset, d.dataset_shortname, array_agg(o.uuid_organisme) AS organisms
            FROM gn_meta.t_datasets AS d
                LEFT JOIN gn_meta.cor_dataset_actor AS a
                    ON (d.id_dataset = a.id_dataset AND a.id_nomenclature_actor_role IN (
                        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '2'), -- Financeur
                        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5'), -- Fournisseur
                        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6') -- Producteur
                    ))
                LEFT JOIN utilisateurs.bib_organismes AS o
                    ON o.id_organisme = a.id_organism
            GROUP BY d.id_dataset, d.dataset_shortname
            ORDER BY d.id_dataset
        ) AS organisms_by_dataset
            LEFT JOIN utilisateurs.bib_organismes AS o
                ON o.uuid_organisme = organisms[1]
        GROUP BY o.nom_organisme, organisms[1]
        ORDER BY organism_name
    )
    SELECT
        dbo.organism_name,
        dbo.organism_uuid,
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN datasets_by_organism AS dbo
            ON s.id_dataset = ANY(dbo.datasets_ids)
    GROUP BY dbo.organism_name, dbo.organism_uuid
    ORDER BY dbo.organism_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
