-- Script to export observations counts by organisms (productor or provider)
-- Usage (from local computer): cat ./observations_count_by_organisms.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_organisms.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH datasets_by_organism AS (
        SELECT organism_name, organism_uuid, datasets_ids
        FROM (
            SELECT o.nom_organisme, o.uuid_organisme, ARRAY_AGG(d.id_dataset ORDER BY d.id_dataset ASC)
            FROM utilisateurs.bib_organismes AS o
                JOIN gn_meta.cor_dataset_actor AS a
                    ON o.id_organisme = a.id_organism
                JOIN  gn_meta.t_datasets AS d
                    ON d.id_dataset = a.id_dataset
            WHERE a.id_nomenclature_actor_role IN (
                    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5'),
                    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
                )
            GROUP BY o.nom_organisme, o.uuid_organisme
            ORDER BY o.nom_organisme
        ) AS p (organism_name, organism_uuid, datasets_ids)
    )
    SELECT
        dbo.organism_name,
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN datasets_by_organism AS dbo
            ON s.id_dataset = ANY(dbo.datasets_ids)
    GROUP BY dbo.organism_name
    ORDER BY dbo.organism_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
