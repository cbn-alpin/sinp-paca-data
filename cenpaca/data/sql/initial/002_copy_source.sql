BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into sources'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';
SET search_path = gn_synthese;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "temp_sources" table if already exists'
DROP TABLE IF EXISTS temp_sources ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "temp_sources" table from "t_sources"'
CREATE TABLE temp_sources AS
TABLE t_sources
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "temp_sources" to GeoNature DB owner'
ALTER TABLE temp_sources OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to temp_sources'
COPY temp_sources (
    name_source,
    desc_source,
    entity_source_pk_field,
    url_source,
    meta_create_date,
    meta_update_date
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy "temp_sources" data to "t_sources" if not exist'
INSERT INTO t_sources(
    name_source,
    desc_source,
    entity_source_pk_field,
    url_source,
    meta_create_date,
    meta_update_date
)
SELECT
    name_source,
    desc_source,
    entity_source_pk_field,
    url_source,
    meta_create_date,
    meta_update_date
FROM temp_sources AS tmp
WHERE NOT EXISTS (
    SELECT 'X'
    FROM t_sources AS ts
    WHERE ts.name_source = tmp.name_source
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
