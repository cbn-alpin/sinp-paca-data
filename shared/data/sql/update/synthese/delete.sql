BEGIN;
-- This file contain a variable "${syntheseImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Delete imported synthese with meta_last_action = D.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch deletion in "synthese" of the imported observations'
-- TODO: delete cascade or not ?
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${syntheseImportTable}', 'D') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to delete in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to delete % observations from %', step, offsetCnt ;

        WITH obs_to_delete AS (
            SELECT unique_id_sinp AS unique_id, source_key
            FROM gn_imports.${syntheseImportTable}
            WHERE meta_last_action = 'D'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        )
        DELETE FROM ONLY gn_synthese.synthese
        WHERE unique_id_sinp IN (SELECT DISTINCT unique_id FROM obs_to_delete)
            OR entity_source_pk_value IN (SELECT DISTINCT source_key FROM obs_to_delete) ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Removed synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
