BEGIN;
-- This file contain a variable "${afImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert imported acquisition frameworks with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "t_acquisition_frameworks" of the imported acquisition frameworks'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${afImportTable}', 'I') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "t_acquisition_frameworks" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % acquisition frameworks from %', step, offsetCnt ;

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Inserting PARENT acquisition frameworks data to "t_acquisition_frameworks" if not exist' ;
        INSERT INTO gn_meta.t_acquisition_frameworks (
            unique_acquisition_framework_id,
            acquisition_framework_name,
            acquisition_framework_desc,
            id_nomenclature_territorial_level,
            territory_desc,
            keywords,
            id_nomenclature_financing_type,
            target_description,
            ecologic_or_geologic_target,
            acquisition_framework_parent_id,
            is_parent,
            acquisition_framework_start_date,
            acquisition_framework_end_date,
            meta_create_date,
            meta_update_date
        )
        SELECT
            unique_id,
            name,
            description,
            id_nomenclature_territorial_level,
            territory_desc,
            keywords,
            id_nomenclature_financing_type,
            target_description,
            ecologic_or_geologic_target,
            NULL,
            is_parent,
            start_date,
            end_date,
            meta_create_date,
            meta_update_date
        FROM gn_imports.${afImportTable} AS afit
        WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_meta.t_acquisition_frameworks AS taf
                WHERE taf.acquisition_framework_name = afit.name
                    OR taf.unique_acquisition_framework_id = afit.unique_id
            )
            AND afit.is_parent = True
            AND afit.meta_last_action = 'I'
        ORDER BY afit.gid ASC
        -- With NOT EXISTS don't use OFFSET because it's eliminate previously inserted rows.
        -- OFFSET offsetCnt
        LIMIT step ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted PARENT acquistion frameworks rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Inserting CHILDREN acquisition frameworks data to "t_acquisition_frameworks" if not exist' ;
        INSERT INTO gn_meta.t_acquisition_frameworks (
            unique_acquisition_framework_id,
            acquisition_framework_name,
            acquisition_framework_desc,
            id_nomenclature_territorial_level,
            territory_desc,
            keywords,
            id_nomenclature_financing_type,
            target_description,
            ecologic_or_geologic_target,
            acquisition_framework_parent_id,
            is_parent,
            acquisition_framework_start_date,
            acquisition_framework_end_date,
            meta_create_date,
            meta_update_date
        )
        SELECT
            unique_id,
            name,
            description,
            id_nomenclature_territorial_level,
            territory_desc,
            keywords,
            id_nomenclature_financing_type,
            target_description,
            ecologic_or_geologic_target,
            (
                SELECT taf_parent.id_acquisition_framework
                FROM gn_meta.t_acquisition_frameworks AS taf_parent
                WHERE taf_parent.unique_acquisition_framework_id::text = afit.parent_code
                    OR taf_parent.acquisition_framework_name = afit.parent_code
            ),
            is_parent,
            start_date,
            end_date,
            meta_create_date,
            meta_update_date
        FROM gn_imports.${afImportTable} AS afit
        WHERE NOT EXISTS (
                SELECT 'X'
                FROM gn_meta.t_acquisition_frameworks AS taf
                WHERE taf.acquisition_framework_name = afit.name
                    OR taf.unique_acquisition_framework_id = afit.unique_id
            )
            AND afit.is_parent = False
            AND afit.meta_last_action = 'I'
        ORDER BY afit.gid ASC
        -- With NOT EXISTS don't use OFFSET because it's eliminate previously inserted rows.
        -- OFFSET offsetCnt
        LIMIT step ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted CHILDREN acquistion frameworks rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between acquisition framework and "SINP volets"' ;
        INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
            id_acquisition_framework,
            id_nomenclature_voletsinp
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                ref_nomenclatures.get_id_nomenclature('VOLET_SINP', UNNEST(afit.cor_voletsinp))
            FROM gn_imports.${afImportTable} AS afit
            WHERE afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_voletsinp DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "SINP volets" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between acquisition framework and objectifs' ;
        INSERT INTO gn_meta.cor_acquisition_framework_objectif (
            id_acquisition_framework,
            id_nomenclature_objectif
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', UNNEST(afit.cor_objectifs))
            FROM gn_imports.${afImportTable} AS afit
            WHERE afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_objectif DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "objectifs" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between acquisition framework and actor => ORGANISM' ;
        INSERT INTO gn_meta.cor_acquisition_framework_actor (
            id_acquisition_framework,
            id_organism,
            id_nomenclature_actor_role
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                COALESCE(utilisateurs.get_id_organism_by_name(elems ->> 0), utilisateurs.get_id_organism_by_uuid((elems ->> 0)::uuid)),
                ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
            FROM gn_imports.${afImportTable} AS afit,
                json_array_elements(array_to_json(afit.cor_actors_organism)) elems
            WHERE afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => ORGANISM" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between acquisition framework and actor => USER' ;
        INSERT INTO gn_meta.cor_acquisition_framework_actor (
            id_acquisition_framework,
            id_role,
            id_nomenclature_actor_role
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                COALESCE(utilisateurs.get_id_role_by_identifier(elems ->> 0), utilisateurs.get_id_role_by_uuid((elems ->> 0)::uuid)),
                ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
            FROM gn_imports.${afImportTable} AS afit,
                json_array_elements(array_to_json(afit.cor_actors_user)) elems
            WHERE afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_role DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => USER" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert publications' ;
        INSERT INTO gn_meta.sinp_datatype_publications (
            unique_publication_id,
            publication_reference,
            publication_url
        )
            SELECT
                uuid(elems ->> 'uuid'),
                elems ->> 'reference',
                elems ->> 'url'
            FROM gn_imports.${afImportTable} AS afit,
                jsonb_array_elements(afit.cor_publications) elems
            WHERE NOT EXISTS (
                    SELECT 'X'
                    FROM gn_meta.sinp_datatype_publications AS sdp
                    WHERE sdp.publication_reference = elems ->> 'reference'
                        OR sdp.unique_publication_id = uuid(elems ->> 'uuid')
                )
                AND afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            -- With NOT EXISTS don't use OFFSET because it's eliminate previously inserted rows.
            -- OFFSET offsetCnt
            LIMIT step
        ON CONFLICT DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "publications" rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Insert link between acquisition framework and publications' ;
        INSERT INTO gn_meta.cor_acquisition_framework_publication (
            id_acquisition_framework,
            id_publication
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                gn_meta.get_id_publication_by_reference(elems ->> 'reference')
            FROM gn_imports.${afImportTable} AS afit,
                jsonb_array_elements(afit.cor_publications) elems
            WHERE afit.meta_last_action = 'I'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_publication DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed orphans "publications" rows: %', affectedRows ;


        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
