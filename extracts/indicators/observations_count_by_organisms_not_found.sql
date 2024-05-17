-- Script to export observations counts by organisms (productor or provider) not found
-- Usage (from local computer): cat ./observations_count_by_organisms_not_found.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_organisms_not_found.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH datasets_by_organism AS (
        SELECT DISTINCT
            COALESCE(organisms_label, '-- Non renseigné --') AS organism_name,
            organisms_uuid AS organism_uuid,
            ARRAY_AGG(id_dataset ORDER BY id_dataset ASC) AS datasets_ids
        FROM (
            SELECT DISTINCT
                d.id_dataset,
                d.dataset_shortname,
                STRING_AGG(o.nom_organisme, ' | ') AS organisms_label,
                STRING_AGG(o.uuid_organisme::varchar, ', ') AS organisms_uuid
            FROM gn_meta.t_datasets AS d
                LEFT JOIN gn_meta.cor_dataset_actor AS a
                    ON (d.id_dataset = a.id_dataset AND a.id_nomenclature_actor_role IN (
                        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5'), -- Fournisseur
                        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6') -- Producteur
                    ))
                LEFT JOIN utilisateurs.bib_organismes AS o
                    ON o.id_organisme = a.id_organism
            GROUP BY d.id_dataset, d.dataset_shortname
            ORDER BY d.id_dataset
        ) AS organisms_by_dataset
        GROUP BY organisms_label, organisms_uuid
        ORDER BY organism_name
    )
    SELECT DISTINCT
        d.dataset_shortname,
        d.id_dataset AS dataset_id,
        d.unique_dataset_id AS dataset_uuid,
        so.name_source AS source_name,
        COUNT(s.id_synthese) AS obs_nbr
    FROM datasets_by_organism AS dbo
        JOIN gn_meta.t_datasets AS d
            ON d.id_dataset = ANY(dbo.datasets_ids)
        JOIN gn_synthese.synthese AS s
            ON s.id_dataset = d.id_dataset
        JOIN gn_synthese.t_sources AS so
            ON so.id_source = s.id_source
    WHERE dbo.organism_name = '-- Non renseigné --'
    GROUP BY d.dataset_shortname, d.id_dataset, d.unique_dataset_id, so.name_source
    ORDER BY d.dataset_shortname
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
