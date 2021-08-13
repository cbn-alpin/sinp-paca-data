BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Transfert data from "synthese_paca" to "synthese"...'
WITH import_dataset AS (
    SELECT id_dataset AS id
    FROM gn_meta.t_datasets
    WHERE unique_dataset_id = '8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6'
)
INSERT INTO gn_synthese.synthese (
    id_source,
    entity_source_pk_value,
    id_dataset,
    count_min,
    count_max,
    cd_nom,
    nom_cite,
    altitude_min,
    altitude_max,
    the_geom_4326,
    the_geom_point,
    the_geom_local,
    date_min,
    date_max,
    observers,
    comment_description,
    meta_validation_date
)
SELECT
    id_source,
    entity_source_pk_value,
    import_dataset.id,
    count_min,
    count_max,
    cd_nom,
    nom_cite,
    altitude_min,
    altitude_max,
    the_geom_4326,
    the_geom_point,
    the_geom_local,
    date_min,
    date_max,
    observers,
    comment_description,
    meta_validation_date
FROM imports.synthese_cenpaca AS scp, import_dataset
WHERE NOT EXISTS (
    SELECT 'X'
    FROM gn_synthese.synthese AS s, import_dataset
    WHERE s.entity_source_pk_value = scp.entity_source_pk_value
        AND s.id_dataset = import_dataset.id
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
