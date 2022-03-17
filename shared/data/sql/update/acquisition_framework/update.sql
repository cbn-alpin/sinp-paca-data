BEGIN;
-- This file contain a variable "${afImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported acquisition frameworks with meta_last_action = U.'
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
    stopAt := gn_imports.computeImportTotal('gn_imports.${afImportTable}', 'U') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update in "t_acquisition_frameworks" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % acquisition frameworks from %', step, offsetCnt ;

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Updating PARENT acquisition frameworks...' ;
        UPDATE gn_meta.t_acquisition_frameworks AS taf SET
            unique_acquisition_framework_id = afit.unique_id,
            acquisition_framework_name = afit.name,
            acquisition_framework_desc = afit.description,
            id_nomenclature_territorial_level = afit.id_nomenclature_territorial_level,
            territory_desc = afit.territory_desc,
            keywords = afit.keywords,
            id_nomenclature_financing_type = afit.id_nomenclature_financing_type,
            target_description = afit.target_description,
            ecologic_or_geologic_target = afit.ecologic_or_geologic_target,
            acquisition_framework_parent_id = afit.parent_id,
            is_parent = afit.is_parent,
            acquisition_framework_start_date = afit.start_date,
            acquisition_framework_end_date = afit.end_date,
            meta_create_date = afit.meta_create_date,
            meta_update_date = afit.meta_update_date
        FROM (
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
                NULL::int AS parent_id,
                is_parent,
                start_date,
                end_date,
                meta_create_date,
                meta_update_date
            FROM gn_imports.${afImportTable}
            WHERE meta_last_action = 'U'
                AND is_parent = True
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS afit
        WHERE ( -- TODO: check if OR below is a good idea or not !
                afit.name = taf.acquisition_framework_name
                OR
                afit.unique_id = taf.unique_acquisition_framework_id
            ) ;
            -- Avoid using meta_update_date because it's not always correct.
            -- AND afit.meta_update_date > taf.meta_update_date ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated PARENT acquisition frameworks rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Updating CHILDREN acquisition frameworks...' ;
        UPDATE gn_meta.t_acquisition_frameworks AS taf SET
            unique_acquisition_framework_id = afit.unique_id,
            acquisition_framework_name = afit.name,
            acquisition_framework_desc = afit.description,
            id_nomenclature_territorial_level = afit.id_nomenclature_territorial_level,
            territory_desc = afit.territory_desc,
            keywords = afit.keywords,
            id_nomenclature_financing_type = afit.id_nomenclature_financing_type,
            target_description = afit.target_description,
            ecologic_or_geologic_target = afit.ecologic_or_geologic_target,
            acquisition_framework_parent_id = afit.parent_id,
            is_parent = afit.is_parent,
            acquisition_framework_start_date = afit.start_date,
            acquisition_framework_end_date = afit.end_date,
            meta_create_date = afit.meta_create_date,
            meta_update_date = afit.meta_update_date
        FROM (
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
                    WHERE taf_parent.unique_acquisition_framework_id::text = afit0.parent_code
                        OR taf_parent.acquisition_framework_name = afit0.parent_code
                ) AS parent_id,
                is_parent,
                start_date,
                end_date,
                meta_create_date,
                meta_update_date
            FROM gn_imports.${afImportTable} AS afit0
            WHERE meta_last_action = 'U'
                AND is_parent = False
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS afit
        WHERE ( -- TODO: check if OR below is a good idea or not !
                afit.name = taf.acquisition_framework_name
                OR
                afit.unique_id = taf.unique_acquisition_framework_id
            ) ;
            -- Avoid using meta_update_date because it's not always correct.
            -- AND afit.meta_update_date > taf.meta_update_date ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated CHILDREN acquisition frameworks rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of "Volets SINP" links...' ;
        DELETE FROM ONLY gn_meta.cor_acquisition_framework_voletsinp
        WHERE id_acquisition_framework IN (
            SELECT taf.id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks AS taf
                JOIN gn_imports.${afImportTable} AS afit
                    ON (
                        afit.name = taf.acquisition_framework_name
                        OR
                        afit.unique_id = taf.unique_acquisition_framework_id
                    )
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "Volets SINP" link rows: %', affectedRows ;


        RAISE NOTICE 'Insert link between acquisition framework and SINP "volets"' ;
        INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
            id_acquisition_framework,
            id_nomenclature_voletsinp
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                ref_nomenclatures.get_id_nomenclature('VOLET_SINP', UNNEST(afit.cor_voletsinp))
            FROM gn_imports.${afImportTable} AS afit
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_voletsinp DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "Volets SINP" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of "objectifs" links...' ;
        DELETE FROM ONLY gn_meta.cor_acquisition_framework_objectif
        WHERE id_acquisition_framework IN (
            SELECT taf.id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks AS taf
                JOIN gn_imports.${afImportTable} AS afit
                    ON (
                        afit.name = taf.acquisition_framework_name
                        OR
                        afit.unique_id = taf.unique_acquisition_framework_id
                    )
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "objectifs" link rows: %', affectedRows ;


        RAISE NOTICE 'Insert link between acquisition framework and objectifs' ;
        INSERT INTO gn_meta.cor_acquisition_framework_objectif (
            id_acquisition_framework,
            id_nomenclature_objectif
        )
            SELECT
                COALESCE(gn_meta.get_id_acquisition_framework_by_name(afit.name), gn_meta.get_id_acquisition_framework_by_uuid(afit.unique_id)),
                ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', UNNEST(afit.cor_objectifs))
            FROM gn_imports.${afImportTable} AS afit
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_objectif DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "objectifs" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of "actors" links...' ;
        DELETE FROM ONLY gn_meta.cor_acquisition_framework_actor
        WHERE id_acquisition_framework IN (
            SELECT taf.id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks AS taf
                JOIN gn_imports.${afImportTable} AS afit
                    ON (
                        afit.name = taf.acquisition_framework_name
                        OR
                        afit.unique_id = taf.unique_acquisition_framework_id
                    )
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "actors" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => ORGANISM" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_role DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "actor => USER" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Updating existing publications' ;
        UPDATE gn_meta.sinp_datatype_publications AS sdp SET
            unique_publication_id = pub.uuid,
            publication_reference = pub.reference,
            publication_url = pub.url
        FROM (
            SELECT
                uuid(elems ->> 'uuid') AS uuid,
                elems ->> 'reference' AS reference,
                elems ->> 'url' AS url
            FROM gn_imports.${afImportTable} AS afit,
                jsonb_array_elements(afit.cor_publications) elems
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS pub
        WHERE ( -- TODO: check if OR below is a good idea or not !
                pub.reference = sdp.publication_reference
                OR
                pub.uuid = sdp.unique_publication_id
            ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated publications rows: %', affectedRows ;

        RAISE NOTICE 'Inserting new publications' ;
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
                AND afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted publications rows: %', affectedRows ;


        RAISE NOTICE 'Deletion of "publications" links...' ;
        DELETE FROM ONLY gn_meta.cor_acquisition_framework_publication
        WHERE id_acquisition_framework IN (
            SELECT taf.id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks AS taf
                JOIN gn_imports.${afImportTable} AS afit
                    ON (
                        afit.name = taf.acquisition_framework_name
                        OR
                        afit.unique_id = taf.unique_acquisition_framework_id
                    )
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "publications" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'U'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_publication DO NOTHING ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Inserted "publications" link rows: %', affectedRows ;


        RAISE NOTICE 'Cleaning of orphans publications...' ;
        DELETE FROM ONLY gn_meta.sinp_datatype_publications
        WHERE (
                unique_publication_id::TEXT IN (
                    SELECT elems ->> 'uuid'
                    FROM gn_imports.${afImportTable} AS afit,
                        jsonb_array_elements(afit.cor_publications) elems
                    ORDER BY afit.gid ASC
                    LIMIT step
                    OFFSET offsetCnt
                ) OR publication_reference IN (
                    SELECT elems ->> 'reference'
                    FROM gn_imports.${afImportTable} AS afit,
                        jsonb_array_elements(afit.cor_publications) elems
                    ORDER BY afit.gid ASC
                    LIMIT step
                    OFFSET offsetCnt
                )
            ) AND id_publication NOT IN (
                SELECT DISTINCT id_publication
                FROM gn_meta.cor_acquisition_framework_publication
            );
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed orphans "publications" rows: %', affectedRows ;


        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
