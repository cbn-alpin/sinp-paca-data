BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and organisms table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports organisms table if already exists'
DROP TABLE IF EXISTS gn_imports.:organismImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports organisms table from "bib_organismes" with additional fields'
CREATE TABLE gn_imports.:organismImportTable AS
    SELECT
        NULL::INT AS gid,
        uuid_organisme AS unique_id,
        nom_organisme AS name,
        adresse_organisme AS address,
        cp_organisme AS postal_code,
        ville_organisme AS city,
        tel_organisme AS phone,
        fax_organisme AS fax,
        email_organisme AS email,
        url_organisme AS organism_url,
        url_logo AS logo_url,
        NULL::JSONB AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM utilisateurs.bib_organismes
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports organisms table'
\set importTablePk 'pk_':organismImportTable
ALTER TABLE gn_imports.:organismImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports organisms table'
\set nameIdx 'idx_unique_':organismImportTable'_name'
CREATE UNIQUE INDEX :nameIdx
    ON gn_imports.:organismImportTable USING btree (name);

\set uniqueIdIdx 'idx_unique_':organismImportTable'_unique_id'
CREATE UNIQUE INDEX :uniqueIdIdx
    ON gn_imports.:organismImportTable USING btree (unique_id);

\set updateDateIdx 'idx_':organismImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:organismImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':organismImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:organismImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports organisms to GeoNature DB owner'
ALTER TABLE gn_imports.:organismImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import organisms table'
COPY gn_imports.:organismImportTable (
    unique_id,
    name,
    address,
    postal_code,
    city,
    phone,
    fax,
    email,
    organism_url,
    logo_url,
    additional_data,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
