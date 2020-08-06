BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into sources'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';
SET search_path = gn_synthese;

-- TODO: replace this by import via table in schema "imports"
\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to t_sources'
COPY t_sources (
    name_source,
    desc_source,
    entity_source_pk_field,
    url_source,
    meta_create_date,
    meta_update_date
)
FROM :'csvFilePath'
WITH DELIMITER E'\t' CSV HEADER NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
