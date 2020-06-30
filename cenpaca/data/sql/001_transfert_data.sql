BEGIN;

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
FROM imports.synthese_cenpaca AS scp
WHERE NOT EXISTS (
    SELECT 'X'
    FROM gn_synthese.synthese AS s
    WHERE s.entity_source_pk_value = scp.entity_source_pk_value
        AND s.id_dataset = scp.i_dataset
)

COMMIT;
