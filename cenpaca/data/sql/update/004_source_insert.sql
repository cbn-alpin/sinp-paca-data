BEGIN;
-- This file contain a variable "${sourcesImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert to gn_imports.sources imported sources data with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the source data imported into "t_sources" if they do not exist'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:sourcesImportTable" query.
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to insert in "t_sources" table' ;
    WHILE offsetCnt < stopAt LOOP
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
        FROM gn_imports.${sourcesImportTable} AS sit
        WHERE sit.meta_last_action = 'I'
            AND NOT EXISTS (
                SELECT 'X'
                FROM gn_synthese.t_sources AS ts
                WHERE ts.name_source = sit.name_source
            )
        ORDER BY sit.gid ASC
        LIMIT step
        OFFSET offsetCnt ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Insert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt ;

    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
