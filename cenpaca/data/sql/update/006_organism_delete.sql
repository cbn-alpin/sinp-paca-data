BEGIN;
-- This file contain a variable "${organismsImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Delete imported organisms with meta_last_action = D.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch deletion in "bib_organismes" of the imported organisms'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:organismsImportTable" query.
-- TODO: find a better field than name_source to link because it must be updated too !
-- TODO: delete cascade or not ? Delete users in t_roles before ?
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to delete in "bib_organismes" table' ;
    WHILE offsetCnt < stopAt LOOP
        DELETE FROM ONLY utilisateurs.bib_organismes
        WHERE nom_organisme IN (
            SELECT name
            FROM gn_imports.${organismsImportTable}
            WHERE meta_last_action = 'D'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Delete affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt ;

    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
