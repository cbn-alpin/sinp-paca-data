BEGIN;
-- This file contain a variable "${afImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Delete imported acquisition frameworks with meta_last_action = D.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch deletion in "t_acquisition_frameworks" of the imported acquisition frameworks'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM gn_imports.${afImportTable}" query.
-- TODO: find a better field than name to link because it must be updated too !
-- TODO: delete cascade or not ?
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to delete in "t_acquisition_frameworks" table' ;
    WHILE offsetCnt < stopAt LOOP

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
            WHERE afit.meta_last_action = 'D'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "Volets SINP" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'D'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "objectifs" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'D'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "actors" link rows: %', affectedRows ;


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
            WHERE afit.meta_last_action = 'D'
            ORDER BY afit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "publications" link rows: %', affectedRows ;


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
        RAISE NOTICE 'Removed "publications" rows: %', affectedRows ;


        RAISE NOTICE 'Deletion of acquisition frameworks...' ;
        DELETE FROM ONLY gn_meta.t_acquisition_frameworks
        WHERE acquisition_framework_name IN (
            SELECT name
            FROM gn_imports.${afImportTable}
            WHERE meta_last_action = 'D'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "acquisition frameworks" rows: %', affectedRows ;


        offsetCnt := offsetCnt + (step) ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt ;

    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
