\echo 'i_unique_':sourcesImportTable'_name'

\set val 'i_unique_':sourcesImportTable'_name'
\echo :val;

DROP TABLE IF EXISTS gn_imports.:sourcesImportTable;

CREATE TABLE gn_imports.:sourcesImportTable AS
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

ALTER TABLE gn_imports.:sourcesImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT 'pk_':sourcesImportTable PRIMARY KEY(gid);
