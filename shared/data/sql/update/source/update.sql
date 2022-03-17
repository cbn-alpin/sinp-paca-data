BEGIN;
-- This file contain a variable "${sourceImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update to gn_imports.sources imported sources data with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating of the source data imported into "t_sources"'
-- TODO: find a better field than name_source to link because it must be updated too !
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${sourceImportTable}', 'U') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;


    RAISE NOTICE 'Start to loop on data to update in "t_sources" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % sources from %', step, offsetCnt ;

        UPDATE gn_synthese.t_sources AS ts SET
            name_source = sit.name_source,
            desc_source = sit.desc_source,
            entity_source_pk_field = sit.entity_source_pk_field,
            url_source = sit.url_source,
            meta_create_date = sit.meta_create_date,
            meta_update_date = sit.meta_update_date
        FROM (
            SELECT
                name_source,
                desc_source,
                entity_source_pk_field,
                url_source,
                meta_create_date,
                meta_update_date
            FROM gn_imports.${sourceImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS sit
        WHERE sit.name_source = ts.name_source ;
            -- Avoid using meta_update_date because it's not always correct.
            -- AND sit.meta_update_date > ts.meta_update_date ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Update affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
