BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into sources'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';
SET search_path = gn_synthese;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "tmp_sources" table if already exists'
DROP TABLE IF EXISTS tmp_sources ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_sources" table from "t_sources"'
CREATE TABLE tmp_sources AS
TABLE t_sources
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "tmp_sources" to GeoNature DB owner'
ALTER TABLE tmp_sources OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to tmp_sources'
COPY tmp_sources (
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
\echo 'Copy "tmp_sources" data to "t_sources" if not exist'
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
FROM tmp_sources AS tmp
WHERE NOT EXISTS (
    SELECT 'X'
    FROM t_sources AS ts
    WHERE ts.name_source = tmp.name_source
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
