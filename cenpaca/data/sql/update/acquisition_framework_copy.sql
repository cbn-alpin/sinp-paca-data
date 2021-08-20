BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and acquisition frameworks table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports acquisition frameworks table if already exists'
DROP TABLE IF EXISTS gn_imports.:afImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports acquisition frameworks table from "t_acquisition_frameworks" with additional fields'
CREATE TABLE gn_imports.:afImportTable AS
    SELECT
        NULL::INT AS gid,
        unique_acquisition_framework_id AS unique_id,
        acquisition_framework_name AS name,
        acquisition_framework_desc AS description,
        id_nomenclature_territorial_level,
        territory_desc,
        keywords,
        id_nomenclature_financing_type,
        target_description,
        ecologic_or_geologic_target,
        NULL::VARCHAR(255) AS parent_code,
        is_parent,
        acquisition_framework_start_date AS start_date,
        acquisition_framework_end_date AS end_date,
        NULL::VARCHAR(255)[] AS cor_objectifs,
        NULL::VARCHAR(255)[] AS cor_voletsinp,
        NULL::VARCHAR(255)[][] AS cor_actors_organism,
        NULL::VARCHAR(255)[][] AS cor_actors_user,
        NULL::JSONB AS cor_publications,
        NULL::JSONB AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM gn_meta.t_acquisition_frameworks
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports acquisition frameworks table'
\set importTablePk 'pk_':afImportTable
ALTER TABLE gn_imports.:afImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports acquisition frameworks table'
\set nameIdx 'idx_unique_':afImportTable'_name'
CREATE UNIQUE INDEX :nameIdx
    ON gn_imports.:afImportTable USING btree (name);

\set uniqueIdIdx 'idx_unique_':afImportTable'_unique_id'
CREATE UNIQUE INDEX :uniqueIdIdx
    ON gn_imports.:afImportTable USING btree (unique_id);

\set updateDateIdx 'idx_':afImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:afImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':afImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:afImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports acquisition frameworks to GeoNature DB owner'
ALTER TABLE gn_imports.:afImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import acquisition frameworks table'
COPY gn_imports.:afImportTable (
    unique_id,
    name,
    description,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    parent_code,
    is_parent,
    start_date,
    end_date,
    cor_objectifs,
    cor_voletsinp,
    cor_actors_organism,
    cor_actors_user,
    cor_publications,
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
