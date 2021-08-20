BEGIN;
-- This file contain a variable "${datasetImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Delete imported datasets with meta_last_action = D.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch deletion in "t_datasets" of the imported datasets'
-- TODO: delete cascade or not ?
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${datasetImportTable}', 'D') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to delete in "t_datasets" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to delete % datasets from %', step, offsetCnt ;

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of "territory" links...' ;
        DELETE FROM ONLY gn_meta.cor_dataset_territory
        WHERE id_dataset IN (
            SELECT td.id_dataset
            FROM gn_meta.t_datasets AS td
                JOIN gn_imports.${datasetImportTable} AS dit
                    ON (
                        dit.name = td.dataset_name
                        OR
                        dit.unique_id = td.unique_dataset_id
                    )
            WHERE dit.meta_last_action = 'D'
            ORDER BY dit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "territory" link rows: %', affectedRows ;

        -- TODO : handle protocol

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of "actors" links...' ;
        DELETE FROM ONLY gn_meta.cor_dataset_actor
        WHERE id_dataset IN (
            SELECT td.id_dataset
            FROM gn_meta.t_datasets AS td
                JOIN gn_imports.${datasetImportTable} AS dit
                    ON (
                        dit.name = td.dataset_name
                        OR
                        dit.unique_id = td.unique_dataset_id
                    )
            WHERE dit.meta_last_action = 'D'
            ORDER BY dit.gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;
        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "actors" link rows: %', affectedRows ;


        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Deletion of datasets...' ;
        WITH dataset_to_delete AS (
            SELECT name, unique_id
            FROM gn_imports.${datasetImportTable}
            WHERE meta_last_action = 'D'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        )
        DELETE FROM ONLY gn_meta.t_datasets
        WHERE dataset_name IN (SELECT name FROM dataset_to_delete)
            OR unique_dataset_id IN (SELECT unique_id FROM dataset_to_delete) ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed "datasets" rows: %', affectedRows ;


        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
