BEGIN;
-- This file contain a variable "${usersImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Delete imported users with meta_last_action = D.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch deletion in "t_roles" of the imported users'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:usersImportTable" query.
-- TODO: find a better field than identifier to link because it must be updated too !
-- TODO: delete cascade or not ?
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to delete in "t_roles" table' ;
    WHILE offsetCnt < stopAt LOOP
        DELETE FROM ONLY utilisateurs.t_roles
        WHERE identifiant IN (
            SELECT identifier
            FROM gn_imports.${usersImportTable}
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
