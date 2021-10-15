\echo 'Update synthese table with data store in temporary table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -v csvFilePath="<path-to-csv-to-import>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "admin" -d "geonature2db" -v csvFilePath="/home/geonat/data/cenpaca/data/raw/synthese.fix-2021-06-25.csv" -f ~/data/cenpaca/data/sql/fix/002_fix_sensitivity.sql
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove table tmp_synthese_fix2_cenpaca if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_synthese_fix2_cenpaca ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create temp table to store synthese fix' ;
CREATE TABLE gn_synthese.tmp_synthese_fix2_cenpaca (
    id SERIAL PRIMARY KEY,
    unique_id_sinp uuid NULL,
    id_nomenclature_sensitivity int4 NULL,
    CONSTRAINT unique_tmp_synthese_fix2_cenpaca_id_sinp UNIQUE (unique_id_sinp)
) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to fix temp table'
COPY gn_synthese.tmp_synthese_fix2_cenpaca (
    unique_id_sinp,
    id_nomenclature_sensitivity
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' QUOTE '#' ESCAPE '\';


\echo '-------------------------------------------------------------------------------'
\echo 'Create unique index on fix temp table for unique_id_sinp column'
CREATE UNIQUE INDEX IF NOT EXISTS idx_synthese_fix2_cenpaca_unique_id_sinp
    ON gn_synthese.tmp_synthese_fix2_cenpaca
    USING btree(unique_id_sinp) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Change owner of fix temp table'
ALTER TABLE gn_synthese.tmp_synthese_fix2_cenpaca OWNER TO geonatadmin ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch update data into synthese'
DO $$
DECLARE
    step INTEGER := 9999 ;
    stopAt INTEGER := 30000 ;
    offsetCnt INTEGER := 0 ;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in synthese table' ;
    WHILE offsetCnt < stopAt LOOP
        UPDATE gn_synthese.synthese AS s SET
            id_nomenclature_sensitivity = f.id_nomenclature_sensitivity
        FROM (
            SELECT
                unique_id_sinp,
                id_nomenclature_sensitivity
            FROM gn_synthese.tmp_synthese_fix2_cenpaca
            ORDER BY id ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS f
        WHERE f.unique_id_sinp = s.unique_id_sinp ;

        offsetCnt := offsetCnt + (step + 1) ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt ;

    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean table gn_synthese.synthese '
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;
