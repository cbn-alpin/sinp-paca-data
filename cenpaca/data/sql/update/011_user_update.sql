BEGIN;
-- This file contain a variable "${usersImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported users with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "t_roles" of the imported users'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:usersImportTable" query.
-- TODO: find a better field than identifier to link because it must be updated too !
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in "t_roles" table' ;
    WHILE offsetCnt < stopAt LOOP
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
            FROM gn_imports.${usersImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS uit
        WHERE uit.identifier = tr.identifiant
            AND uit.meta_update_date > tr.date_update ;

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
