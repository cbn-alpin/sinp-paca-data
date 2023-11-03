-- Script to export observations counts by organisms (productor or provider), filter by year.
-- Usage (from local computer): cat ./observations_count_by_organisms_filter_year.sql | sed 's/${year}/<my-year>/g' | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_organisms_<my-year>.csv
-- - <my-year> : replace with the desired year.
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
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN datasets_by_organism AS dbo
            ON s.id_dataset = ANY(dbo.datasets_ids)
    WHERE s.meta_create_date > '${year}-01-01 00:00:00'
        AND s.meta_create_date < '${year}-12-31 23:59:59.999999'
    GROUP BY dbo.organism_name
    ORDER BY dbo.organism_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
