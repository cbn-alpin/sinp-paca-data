BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and users table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports users table if already exists'
DROP TABLE IF EXISTS gn_imports.:usersImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports users table from "t_roles" with additional fields'
CREATE TABLE gn_imports.:usersImportTable AS
    SELECT
        NULL::INT AS gid,
        uuid_role AS unique_id,
        identifiant AS identifier,
        prenom_role AS firstname,
        nom_role AS name,
        email,
        id_organisme,
        remarques AS comment,
        active AS enable,
        champs_addi AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM utilisateurs.t_roles
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports users table'
\set importTablePk 'pk_':usersImportTable
ALTER TABLE gn_imports.:usersImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports users table'
\set identifierIdx 'idx_unique_':usersImportTable'_identifier'
CREATE UNIQUE INDEX :identifierIdx
    ON gn_imports.:usersImportTable USING btree (identifier);

\set uniqueIdIdx 'idx_unique_':usersImportTable'_unique_id'
CREATE UNIQUE INDEX :uniqueIdIdx
    ON gn_imports.:usersImportTable USING btree (unique_id);

\set updateDateIdx 'idx_':usersImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:usersImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':usersImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:usersImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports organisms to GeoNature DB owner'
ALTER TABLE gn_imports.:usersImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import organisms table'
COPY gn_imports.:usersImportTable (
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
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
