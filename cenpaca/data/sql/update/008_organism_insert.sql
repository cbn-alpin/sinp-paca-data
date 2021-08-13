BEGIN;
-- This file contain a variable "${organismsImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Insert imported organisms with meta_last_action = I.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "bib_organismes" of the imported organisms'
-- TODO : set stopAt with a "SELECT COUNT(*) FROM :gn_imports.:organismsImportTable" query.
DO $$
DECLARE
    step INTEGER := 1000 ;
    stopAt INTEGER := 1000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    RAISE NOTICE 'Start to loop on data to insert in "bib_organismes" table' ;
    WHILE offsetCnt < stopAt LOOP
        INSERT INTO utilisateurs.bib_organismes(
            uuid_organisme,
            nom_organisme,
            adresse_organisme,
            cp_organisme,
            ville_organisme,
            tel_organisme,
            fax_organisme,
            email_organisme,
            url_organisme,
            url_logo
        )
        SELECT
            oit.unique_id,
            oit.name,
            oit.address,
            oit.postal_code,
            oit.city,
            oit.phone,
            oit.fax,
            oit.email,
            oit.organism_url,
            oit.logo_url
        FROM gn_imports.${organismsImportTable} AS oit
        WHERE oit.meta_last_action = 'I'
            AND NOT EXISTS (
                SELECT 'X'
                FROM utilisateurs.bib_organismes AS bo
                WHERE bo.nom_organisme = oit.name
            )
        ORDER BY oit.gid ASC
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
