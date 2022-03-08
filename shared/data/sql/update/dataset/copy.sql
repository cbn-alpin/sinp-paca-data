BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and datasets table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports datasets table if already exists'
DROP TABLE IF EXISTS gn_imports.:datasetImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports datasets table from "t_datasets" with additional fields'
CREATE TABLE gn_imports.:datasetImportTable AS
    SELECT
        NULL::INT AS gid,
        unique_dataset_id AS unique_id,
        id_acquisition_framework AS acquisition_framework_id,
        dataset_name AS name,
        dataset_shortname AS shortname,
        dataset_desc AS description,
        id_nomenclature_data_type,
        keywords,
        marine_domain,
        terrestrial_domain,
        id_nomenclature_dataset_objectif,
        bbox_west,
        bbox_east,
        bbox_south,
        bbox_north,
        id_nomenclature_collecting_method,
        id_nomenclature_data_origin,
        id_nomenclature_source_status,
        id_nomenclature_resource_type,
        NULL::VARCHAR(255)[][] AS cor_territory,
        NULL::VARCHAR(255)[][] AS cor_actors_organism,
        NULL::VARCHAR(255)[][] AS cor_actors_user,
        NULL::JSONB AS additional_data,
        NULL::TIMESTAMP AS meta_create_date,
        NULL::TIMESTAMP AS meta_update_date,
        NULL::BPCHAR(1) AS meta_last_action
    FROM gn_meta.t_datasets
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports datasets table'
\set importTablePk 'pk_':datasetImportTable
ALTER TABLE gn_imports.:datasetImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports datasets table'
\set shortnameIdx 'idx_unique_':datasetImportTable'_shortname'
CREATE UNIQUE INDEX :shortnameIdx
    ON gn_imports.:datasetImportTable USING btree (shortname);

\set uniqueIdIdx 'idx_unique_':datasetImportTable'_unique_id'
CREATE UNIQUE INDEX :uniqueIdIdx
    ON gn_imports.:datasetImportTable USING btree (unique_id);

\set updateDateIdx 'idx_':datasetImportTable'_meta_update_date'
CREATE INDEX :updateDateIdx
    ON gn_imports.:datasetImportTable USING btree (meta_update_date);

\set lastActionIdx 'idx_':datasetImportTable'_meta_last_action'
CREATE INDEX :lastActionIdx
    ON gn_imports.:datasetImportTable USING btree (meta_last_action);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports datasets to GeoNature DB owner'
ALTER TABLE gn_imports.:datasetImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import datasets table'
COPY gn_imports.:datasetImportTable (
    unique_id,
    acquisition_framework_id,
    name,
    shortname,
    description,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    cor_territory,
    cor_actors_organism,
    cor_actors_user,
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
