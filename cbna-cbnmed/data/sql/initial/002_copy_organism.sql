BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into organism'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';
SET search_path = utilisateurs;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "tmp_organisms" table if already exists'
DROP TABLE IF EXISTS tmp_organisms ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_organisms" table from "bib_organismes"'
CREATE TABLE tmp_organisms AS
TABLE bib_organismes
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "tmp_organisms" to GeoNature DB owner'
ALTER TABLE tmp_organisms OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to tmp_organisms'
COPY tmp_organisms (
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
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy "tmp_organisms" data to "bib_organismes" if not exist'
INSERT INTO bib_organismes(
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
FROM tmp_organisms AS tmp
WHERE NOT EXISTS (
    SELECT 'X'
    FROM bib_organismes AS bo
    WHERE bo.nom_organisme = tmp.nom_organisme
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
