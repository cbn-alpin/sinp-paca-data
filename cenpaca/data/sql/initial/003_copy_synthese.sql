\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into synthese'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN ;

SET search_path = gn_synthese, public, pg_catalog ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to synthese'
COPY synthese (
    id_source,
    id_module,
    entity_source_pk_value,
    id_dataset,
    count_min,
    count_max,
    cd_nom,
    nom_cite,
    meta_v_taxref,
    sample_number_proof,
    digital_proof,
    non_digital_proof,
    altitude_min,
    altitude_max,
    the_geom_4326,
    the_geom_point,
    the_geom_local,
    date_min,
    date_max,
    validator,
    validation_comment,
    observers,
    determiner,
    id_digitiser,
    comment_context,
    comment_description,
    meta_validation_date,
    meta_create_date,
    meta_update_date,
    last_action
)
FROM :'csvFilePath'
WITH FORMAT CSV HEADER TRUE DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
