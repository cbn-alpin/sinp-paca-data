BEGIN;
-- This file contain a variable "${datasetImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert imported datasets with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "t_datasets" of the imported datasets'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${datasetImportTable}', 'I') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "t_datasets" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % datasets from %', step, offsetCnt ;

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Inserting datasets data to "t_datasets" if not exist' ;
        INSERT INTO gn_meta.t_datasets (
            unique_dataset_id,
            id_acquisition_framework,
            dataset_name,
            dataset_shortname,
            dataset_desc,
            id_nomenclature_data_type,
            keywords,
            marine_domain,
            terrestrial_domain,
            id_nomenclature_dataset_objectif,
            bbox_west,
            bbox_east,
            bbox_south,
            bbox_north,
            id_nomenclature_collecting_method,
            id_nomenclature_data_origin,
            id_nomenclature_source_status,
            id_nomenclature_resource_type,
            meta_create_date,
            meta_update_date
        )
        SELECT
            unique_id,
            acquisition_framework_id,
            name,
            shortname,
            description,
            id_nomenclature_data_type,
            keywords,
            marine_domain,
            terrestrial_domain,
            id_nomenclature_dataset_objectif,
            bbox_west,
            bbox_east,
            bbox_south,
            bbox_north,
            id_nomenclature_collecting_method,
            id_nomenclature_data_origin,
            id_nomenclature_source_status,
            id_nomenclature_resource_type,
            meta_create_date,
            meta_update_date
        FROM gn_imports.${datasetImportTable} AS dit
        WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_meta.t_datasets AS td
                WHERE -- TODO: check if OR below is a good idea or not !
                    td.dataset_shortname = dit.shortname
                    OR td.unique_dataset_id = dit.unique_id
            )
            AND dit.meta_last_action = 'I'
        ORDER BY dit.gid ASC
        -- With NOT EXISTS don't use OFFSET because it's eliminate previously inserted rows.
        -- OFFSET offsetCnt
        LIMIT step ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted datasets rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between dataset and "territory"' ;
        INSERT INTO gn_meta.cor_dataset_territory (
            id_dataset,
            id_nomenclature_territory,
            territory_desc
        )
            SELECT
                COALESCE(gn_meta.get_id_dataset_by_shortname(dit.shortname), gn_meta.get_id_dataset_by_uuid(dit.unique_id)),
                ref_nomenclatures.get_id_nomenclature('TERRITOIRE', elems ->> 0),
                elems ->> 1
            FROM gn_imports.${datasetImportTable} AS dit,
                json_array_elements(array_to_json(dit.cor_territory)) elems
            WHERE dit.meta_last_action = 'I'
            ORDER BY dit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_dataset_territory DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "territory" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between dataset and actor => ORGANISM' ;
        INSERT INTO gn_meta.cor_dataset_actor (
            id_dataset,
            id_organism,
            id_nomenclature_actor_role
        )
            SELECT
                COALESCE(gn_meta.get_id_dataset_by_shortname(dit.shortname), gn_meta.get_id_dataset_by_uuid(dit.unique_id)),
                COALESCE(utilisateurs.get_id_organism_by_name(elems ->> 0), utilisateurs.get_id_organism_by_uuid((elems ->> 0)::uuid)),
                ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
            FROM gn_imports.${datasetImportTable} AS dit,
                json_array_elements(array_to_json(dit.cor_actors_organism)) elems
            WHERE dit.meta_last_action = 'I'
            ORDER BY dit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_organism DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => ORGANISM" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between dataset and actor => USER' ;
        INSERT INTO gn_meta.cor_dataset_actor (
            id_dataset,
            id_role,
            id_nomenclature_actor_role
        )
            SELECT
                COALESCE(gn_meta.get_id_dataset_by_shortname(dit.shortname), gn_meta.get_id_dataset_by_uuid(dit.unique_id)),
                COALESCE(utilisateurs.get_id_role_by_identifier(elems ->> 0), utilisateurs.get_id_role_by_uuid((elems ->> 0)::uuid)),
                ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
            FROM gn_imports.${datasetImportTable} AS dit,
                json_array_elements(array_to_json(dit.cor_actors_user)) elems
            WHERE dit.meta_last_action = 'I'
            ORDER BY dit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_role DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => USER" link rows: %', affectedRows ;


        -- TODO : handle protocol

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
