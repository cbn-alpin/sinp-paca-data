BEGIN;
-- This file contain a variable "${sourceImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert to gn_imports.sources imported sources data with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the source data imported into "t_sources" if they do not exist'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${sourceImportTable}', 'I') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "t_sources" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % sources from %', step, offsetCnt ;

        INSERT INTO gn_synthese.t_sources(
            name_source,
            desc_source,
            entity_source_pk_field,
            url_source,
            meta_create_date,
            meta_update_date
        )
        SELECT
            name_source,
            desc_source,
            entity_source_pk_field,
            url_source,
            meta_create_date,
            meta_update_date
        FROM gn_imports.${sourceImportTable} AS sit
        WHERE sit.meta_last_action = 'I'
            AND NOT EXISTS (
                SELECT 'X'
                FROM gn_synthese.t_sources AS ts
                WHERE ts.name_source = sit.name_source
            )
        ORDER BY sit.gid ASC
        -- With NOT EXISTS don't use OFFSET because it's eliminate previously inserted rows.
        -- OFFSET offsetCnt
        LIMIT step ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Insert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
