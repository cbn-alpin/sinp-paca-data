BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and synthese table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports synthese table if already exists'
DROP TABLE IF EXISTS gn_imports.:syntheseImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports syntheses table from "synthese" with additional fields'
CREATE TABLE gn_imports.:syntheseImportTable AS
    SELECT
        NULL::INT AS gid,
        unique_id_sinp,
        unique_id_sinp_grp,
        entity_source_pk_value AS source_key,
        NULL::VARCHAR(25) AS source_key_grp,
        id_source AS source_id,
        id_dataset AS dataset_id,
        id_module AS  module_id,
        id_nomenclature_geo_object_nature,
        id_nomenclature_grp_typ,
        grp_method,
        id_nomenclature_obs_technique,
        id_nomenclature_bio_status,
        id_nomenclature_bio_condition,
        id_nomenclature_naturalness,
        id_nomenclature_exist_proof,
        id_nomenclature_valid_status,
        id_nomenclature_diffusion_level,
        id_nomenclature_life_stage,
        id_nomenclature_sex,
        id_nomenclature_obj_count,
        id_nomenclature_type_count,
        id_nomenclature_sensitivity,
        id_nomenclature_observation_status,
        id_nomenclature_blurring,
        id_nomenclature_source_status,
        id_nomenclature_info_geo_type,
        id_nomenclature_behaviour,
        id_nomenclature_biogeo_status,
        reference_biblio,
        count_min,
        count_max,
        cd_nom,
        cd_hab,
        nom_cite,
        meta_v_taxref,
        sample_number_proof,
        digital_proof,
        non_digital_proof,
        altitude_min,
        altitude_max,
        depth_min,
        depth_max,
        place_name,
        the_geom_local AS geom,
        precision,
        --id_area_attachment,
        date_min,
        date_max,
        validator,
        validation_comment,
        meta_validation_date AS validation_date,
        observers,
        determiner,
        NULL::TIMESTAMP AS determination_date,
        id_digitiser,
        id_nomenclature_determination_method,
        comment_context,
        comment_description,
        additional_data,
        meta_create_date,
        meta_update_date,
        last_action AS meta_last_action
    FROM gn_synthese.synthese
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports syntheses table'
\set importTablePk 'pk_':syntheseImportTable
ALTER TABLE gn_imports.:syntheseImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports syntheses to GeoNature DB owner'
ALTER TABLE gn_imports.:syntheseImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import syntheses table'
COPY gn_imports.:syntheseImportTable (
    unique_id_sinp,
    unique_id_sinp_grp,
    source_key,
    source_key_grp,
    source_id,
    dataset_id,
    module_id,
    id_nomenclature_geo_object_nature,
    id_nomenclature_grp_typ,
    grp_method,
    id_nomenclature_obs_technique,
    id_nomenclature_bio_status,
    id_nomenclature_bio_condition,
    id_nomenclature_naturalness,
    id_nomenclature_exist_proof,
    id_nomenclature_valid_status,
    id_nomenclature_diffusion_level,
    id_nomenclature_life_stage,
    id_nomenclature_sex,
    id_nomenclature_obj_count,
    id_nomenclature_type_count,
    id_nomenclature_sensitivity,
    id_nomenclature_observation_status,
    id_nomenclature_blurring,
    id_nomenclature_source_status,
    id_nomenclature_info_geo_type,
    id_nomenclature_behaviour,
    id_nomenclature_biogeo_status,
    reference_biblio,
    count_min,
    count_max,
    cd_nom,
    cd_hab,
    nom_cite,
    meta_v_taxref,
    sample_number_proof,
    digital_proof,
    non_digital_proof,
    altitude_min,
    altitude_max,
    depth_min,
    depth_max,
    place_name,
    geom,
    precision,
    --id_area_attachment,
    date_min,
    date_max,
    validator,
    validation_comment,
    validation_date,
    observers,
    determiner,
    determination_date,
    id_digitiser,
    id_nomenclature_determination_method,
    comment_context,
    comment_description,
    additional_data,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports syntheses table'
\set uniqueIdIdx 'idx_unique_':syntheseImportTable'_unique_id'
CREATE UNIQUE INDEX :uniqueIdIdx
    ON gn_imports.:syntheseImportTable USING btree (unique_id_sinp);

\set updateDateIdx 'idx_':syntheseImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:syntheseImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':syntheseImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:syntheseImportTable USING btree (meta_last_action);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
