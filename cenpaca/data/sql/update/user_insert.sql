BEGIN;
-- This file contain a variable "${userImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert imported users with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "t_roles" of the imported users'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${userImportTable}', 'I') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to insert in "t_roles" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % users from %', step, offsetCnt ;

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
        FROM gn_imports.${userImportTable} AS uit
        WHERE uit.meta_last_action = 'I'
            AND NOT EXISTS (
                SELECT 'X'
                FROM utilisateurs.t_roles AS tr
                WHERE tr.identifiant = uit.identifier
                    OR tr.uuid_role = uit.unique_id
            )
        ORDER BY uit.gid ASC
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
