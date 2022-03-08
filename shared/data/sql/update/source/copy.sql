BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and sources table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports sources table if already exists'
DROP TABLE IF EXISTS gn_imports.:sourceImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports sources table from "t_sources" with additional fields'
CREATE TABLE gn_imports.:sourceImportTable AS
    SELECT
        NULL::INT AS gid,
        name_source,
        desc_source,
        entity_source_pk_field,
        url_source,
        NULL::JSONB AS additional_data,
        meta_create_date,
        meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM gn_synthese.t_sources
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports sources table'
\set importTablePk 'pk_':sourceImportTable
ALTER TABLE gn_imports.:sourceImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports sources table'
\set nameIdx 'idx_unique_':sourceImportTable'_name'
CREATE UNIQUE INDEX :nameIdx
    ON gn_imports.:sourceImportTable USING btree (name_source);

\set updateDateIdx 'idx_':sourceImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:sourceImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':sourceImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:sourceImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports sources to GeoNature DB owner'
ALTER TABLE gn_imports.:sourceImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import sources table'
COPY gn_imports.:sourceImportTable (
    name_source,
    desc_source,
    entity_source_pk_field,
    url_source,
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
