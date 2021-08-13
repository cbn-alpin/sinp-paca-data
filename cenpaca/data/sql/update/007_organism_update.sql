BEGIN;
-- This file contain a variable "${organismsImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Update imported organisms with meta_last_action = U.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "bib_organismes" of the imported organisms'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:organismsImportTable" query.
-- TODO: find a better field than nom_organisme to link because it must be updated too !
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in "bib_organismes" table' ;
    WHILE offsetCnt < stopAt LOOP
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
            FROM gn_imports.${organismsImportTable}
            WHERE meta_last_action = 'U'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS oit
        WHERE oit.name = bo.nom_organisme ;

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
