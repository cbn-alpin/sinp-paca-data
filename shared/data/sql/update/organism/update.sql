BEGIN;
-- This file contain a variable "${organismImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported organisms with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "bib_organismes" of the imported organisms'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${organismImportTable}', 'U') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update in "bib_organismes" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % organisms from %', step, offsetCnt ;

        UPDATE utilisateurs.bib_organismes AS bo SET
            uuid_organisme = oit.unique_id,
            nom_organisme = oit.name,
            adresse_organisme = oit.address,
            cp_organisme = oit.postal_code,
            ville_organisme = oit.city,
            tel_organisme = oit.phone,
            fax_organisme = oit.fax,
            email_organisme = oit.email,
            url_organisme = oit.organism_url,
            url_logo = oit.logo_url
        FROM (
            SELECT
                unique_id,
                name,
                address,
                postal_code,
                city,
                phone,
                fax,
                email,
                organism_url,
                logo_url
            FROM gn_imports.${organismImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS oit
        WHERE (
                oit.unique_id = bo.uuid_organisme
                -- La présence de doublon avec le même nom ne permet pas de mettre à jour en se basant sur le nom.
                -- La contrainte "bib_organismes_un" bloque la mise à jour...
                --OR oit.name = bo.nom_organisme
            ) ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Update affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
