BEGIN;
-- This file contain a variable "${usersImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert imported users with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "t_roles" of the imported users'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:usersImportTable" query.
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to insert in "t_roles" table' ;
    WHILE offsetCnt < stopAt LOOP
        INSERT INTO utilisateurs.t_roles(
            uuid_role,
            identifiant,
            prenom_role,
            nom_role,
            email,
            id_organisme,
            remarques,
            active,
            champs_addi,
            date_insert,
            date_update
        )
        SELECT
            unique_id,
            identifier,
            firstname,
            name,
            email,
            id_organisme,
            comment,
            enable,
            additional_data,
            meta_create_date,
            meta_update_date
        FROM gn_imports.${usersImportTable} AS uit
        WHERE uit.meta_last_action = 'I'
            AND NOT EXISTS (
                SELECT 'X'
                FROM utilisateurs.t_roles AS tr
                WHERE tr.identifiant = uit.identifier
            )
        ORDER BY uit.gid ASC
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
