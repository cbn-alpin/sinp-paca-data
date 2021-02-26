\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into synthese'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN ;

SET search_path = gn_synthese, public, pg_catalog ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to synthese'
COPY synthese (
    unique_id_sinp,
    unique_id_sinp_grp,
    entity_source_pk_value,
    id_source,
    id_dataset,
    id_nomenclature_geo_object_nature,
    id_nomenclature_grp_typ,
    grp_method,
    id_nomenclature_obs_technique,
    id_nomenclature_bio_status,
    id_nomenclature_bio_condition,
    id_nomenclature_naturalness,
    id_nomenclature_exist_proof, -- Errors in field values, remove for now !
    id_nomenclature_valid_status,
    id_nomenclature_diffusion_level,
    id_nomenclature_life_stage,
    id_nomenclature_sex, -- Errors in field values, remove for now !
    id_nomenclature_obj_count,
    id_nomenclature_type_count,
    id_nomenclature_sensitivity,
    id_nomenclature_observation_status,
    id_nomenclature_blurring,
    id_nomenclature_source_status,
    id_nomenclature_info_geo_type,
    id_nomenclature_behaviour,
    --id_nomenclature_biogeo_status, -- Missing field !
    reference_biblio,
    count_min,
    count_max,
    cd_nom,
    --cd_hab, -- Missing field !
    nom_cite,
    --sample_number_proof, -- Missing field !
    digital_proof,
    --non_digital_proof, -- Missing field !
    altitude_min,
    altitude_max,
    depth_min,
    depth_max,
    place_name,
    the_geom_local,
    "precision",
    date_min,
    date_max,
    validator,
    validation_comment,
    meta_validation_date,
    observers,
    determiner,
    id_digitiser,
    id_nomenclature_determination_method, -- Errors in field values, remove for now !
    comment_context,
    comment_description,
    additional_data,
    meta_create_date,
    meta_update_date,
    last_action
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update geom fields'
UPDATE synthese SET
    the_geom_4326 = ST_Transform(the_geom_local, 4326),
    the_geom_point = ST_Transform(ST_Centroid(the_geom_local), 4326)
WHERE id_source IN (
    SELECT get_id_source_by_name(tmp.name_source)
    FROM tmp_sources AS tmp
) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Update id_module fields'
UPDATE synthese SET
    id_module = gn_commons.get_id_module_bycode('SYNTHESE')
WHERE id_source IN (
    SELECT get_id_source_by_name(tmp.name_source)
    FROM tmp_sources AS tmp
) ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
