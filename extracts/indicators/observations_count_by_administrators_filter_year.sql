-- Script to export observations counts by administrators, filter by year.
-- Usage (from local computer): cat ./observations_count_by_administrators_filter_year.sql | sed 's/${year}/<my-year>/g' | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_obs_by_administrators_<my-year>.csv
-- - <my-year> : replace with the desired year.
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH datasets_by_administrator AS (
        SELECT administrator_name, datasets_ids
        FROM (
            VALUES
                ('CEN-PACA', ARRAY(
                        SELECT DISTINCT d.id_dataset
                        FROM gn_meta.t_datasets AS d
                            JOIN gn_meta.cor_dataset_actor AS a
                                ON d.id_dataset = a.id_dataset
                        WHERE a.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
                            AND (
                                a.id_organism = utilisateurs.get_id_organism_by_uuid('5a433bd0-2078-25d9-e053-2614a8c026f8')
                                OR a.id_role = utilisateurs.get_id_role_by_identifier('paul.honore')
                            )
                    )
                ),
                ('CBNMED', ARRAY(
                        SELECT DISTINCT d.id_dataset
                        FROM gn_meta.t_datasets AS d
                            JOIN gn_meta.cor_dataset_actor AS a
                                ON d.id_dataset = a.id_dataset
                        WHERE a.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
                            AND (
                                a.id_organism = utilisateurs.get_id_organism_by_uuid('5a433bd0-1fca-25d9-e053-2614a8c026f8')
                                OR a.id_role = utilisateurs.get_id_role_by_identifier('g.debarros')
                                OR a.id_role = utilisateurs.get_id_role_by_identifier('v.noble')
                            )
                    )
                ),
                ('CBNA', ARRAY(
                        SELECT DISTINCT d.id_dataset
                        FROM gn_meta.t_datasets AS d
                            JOIN gn_meta.cor_dataset_actor AS a
                                ON d.id_dataset = a.id_dataset
                        WHERE a.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
                            AND (
                                a.id_organism = utilisateurs.get_id_organism_by_uuid('5a433bd0-1fc0-25d9-e053-2614a8c026f8')
                                OR a.id_role = utilisateurs.get_id_role_by_identifier('jm.genis')
                                OR a.id_role = utilisateurs.get_id_role_by_identifier('m.molinatti')
                            )
                    )
                )
        ) AS p (administrator_name, datasets_ids)
    )
    SELECT
        dbp.administrator_name,
        COUNT(s.id_synthese) AS obs_nbr
    FROM gn_synthese.synthese AS s
        JOIN datasets_by_administrator AS dbp
            ON s.id_dataset = ANY(dbp.datasets_ids)
    WHERE s.meta_create_date > '${year}-01-01 00:00:00'
        AND s.meta_create_date < '${year}-12-31 23:59:59.999999'
    GROUP BY dbp.administrator_name
    ORDER BY dbp.administrator_name
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
