BEGIN;
-- This file contain a variable "${syntheseImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported observations with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "synthese" of the imported observations'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.${syntheseImportTable}" query.
-- TODO: find a better field than name to link because it must be updated too !
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${syntheseImportTable}', 'U') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % observations from %', step, offsetCnt ;

        UPDATE gn_synthese.synthese AS s SET
            unique_id_sinp = sit.unique_id_sinp,
            unique_id_sinp_grp = sit.unique_id_sinp_grp,
            entity_source_pk_value = source_key,
            id_source = sit.source_id,
            id_dataset = sit.dataset_id,
            id_module = sit.module_id,
            id_nomenclature_geo_object_nature = sit.id_nomenclature_geo_object_nature,
            id_nomenclature_grp_typ = sit.id_nomenclature_grp_typ,
            grp_method = sit.grp_method,
            id_nomenclature_obs_technique = sit.id_nomenclature_obs_technique,
            id_nomenclature_bio_status = sit.id_nomenclature_bio_status,
            id_nomenclature_bio_condition = sit.id_nomenclature_bio_condition,
            id_nomenclature_naturalness = sit.id_nomenclature_naturalness,
            id_nomenclature_exist_proof = sit.id_nomenclature_exist_proof,
            id_nomenclature_valid_status = sit.id_nomenclature_valid_status,
            id_nomenclature_diffusion_level = sit.id_nomenclature_diffusion_level,
            id_nomenclature_life_stage = sit.id_nomenclature_life_stage,
            id_nomenclature_sex = sit.id_nomenclature_sex,
            id_nomenclature_obj_count = sit.id_nomenclature_obj_count,
            id_nomenclature_type_count = sit.id_nomenclature_type_count,
            id_nomenclature_sensitivity = sit.id_nomenclature_sensitivity,
            id_nomenclature_observation_status = sit.id_nomenclature_observation_status,
            id_nomenclature_blurring = sit.id_nomenclature_blurring,
            id_nomenclature_source_status = sit.id_nomenclature_source_status,
            id_nomenclature_info_geo_type = sit.id_nomenclature_info_geo_type,
            id_nomenclature_behaviour = sit.id_nomenclature_behaviour,
            id_nomenclature_biogeo_status = sit.id_nomenclature_biogeo_status,
            reference_biblio = sit.reference_biblio,
            count_min = sit.count_min,
            count_max = sit.count_max,
            cd_nom = sit.cd_nom,
            cd_hab = sit.cd_hab,
            nom_cite = sit.nom_cite,
            meta_v_taxref = sit.meta_v_taxref,
            sample_number_proof = sit.sample_number_proof,
            digital_proof = sit.digital_proof,
            non_digital_proof = sit.non_digital_proof,
            altitude_min = sit.altitude_min,
            altitude_max = sit.altitude_max,
            depth_min = sit.depth_min,
            depth_max = sit.depth_max,
            place_name = sit.place_name,
            the_geom_local = sit.geom,
            precision = sit.precision,
            date_min = sit.date_min,
            date_max = sit.date_max,
            validator = sit.validator,
            validation_comment = sit.validation_comment,
            meta_validation_date = sit.validation_date,
            observers = sit.observers,
            determiner = sit.determiner,
            id_digitiser = sit.id_digitiser,
            id_nomenclature_determination_method = sit.id_nomenclature_determination_method,
            comment_context = sit.comment_context,
            comment_description = sit.comment_description,
            additional_data = sit.additional_data,
            meta_create_date = sit.meta_create_date,
            meta_update_date = sit.meta_update_date,
            last_action = sit.meta_last_action
        FROM (
            SELECT
                unique_id_sinp,
                unique_id_sinp_grp,
                source_key,
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
                date_min,
                date_max,
                validator,
                validation_comment,
                validation_date,
                observers,
                determiner,
                id_digitiser,
                id_nomenclature_determination_method,
                comment_context,
                comment_description,
                additional_data,
                meta_create_date,
                meta_update_date,
                meta_last_action
            FROM gn_imports.${syntheseImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS sit
        WHERE sit.unique_id_sinp = s.unique_id_sinp
            AND sit.meta_update_date > s.meta_update_date ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
