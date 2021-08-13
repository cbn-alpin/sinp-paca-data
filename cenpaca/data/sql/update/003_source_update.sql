BEGIN;
-- This file contain a variable "${sourcesImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update to gn_imports.sources imported sources data with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating of the source data imported into "t_sources"'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:sourcesImportTable" query.
-- TODO: find a better field than name_source to link because it must be updated too !
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in "t_sources" table' ;
    WHILE offsetCnt < stopAt LOOP
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
            FROM gn_imports.${sourcesImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS sit
        WHERE sit.name_source = ts.name_source
            AND sit.meta_update_date > ts.meta_update_date ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Update affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt ;

    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
