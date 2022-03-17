BEGIN;
-- This file contain a variable "${userImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported users with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "t_roles" of the imported users'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${userImportTable}', 'U') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update in "t_roles" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % users from %', step, offsetCnt ;

        UPDATE utilisateurs.t_roles AS tr SET
            uuid_role = uit.unique_id,
            identifiant = uit.identifier,
            prenom_role = uit.firstname,
            nom_role = uit.name,
            email = uit.email,
            id_organisme = uit.id_organisme,
            remarques = uit.comment,
            active = uit.enable,
            champs_addi = uit.additional_data,
            date_insert = uit.meta_create_date,
            date_update = uit.meta_update_date
        FROM (
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
                meta_update_date,
                meta_last_action
            FROM gn_imports.${userImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS uit
        WHERE ( -- TODO: check if OR below is a good idea or not !
                uit.identifier = tr.identifiant
                OR
                uit.unique_id = tr.uuid_role
            ) ;
            -- Avoid using meta_update_date because it's not always correct.
            -- AND uit.meta_update_date > tr.date_update ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Update affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
