\echo 'Update synthese table with data store in temporary table.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -v csvFilePath="<path-to-csv-to-import>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "admin" -d "geonature2db" -v csvFilePath="/home/geonat/data/cenpaca/data/raw/synthese.fix-2021-03-24.csv" -f ~/data/cenpaca/data/sql/fix/001_fix_date_count.sql
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove table tmp_synthese_fix_cenpaca if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_synthese_fix_cenpaca ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create temp table to store synthese fix' ;
CREATE TABLE gn_synthese.tmp_synthese_fix_cenpaca (
    id SERIAL PRIMARY KEY,
    unique_id_sinp uuid NULL,
    count_min int4 NULL,
    count_max int4 NULL,
    date_min timestamp NOT NULL,
    date_max timestamp NOT NULL,
    additional_data jsonb NULL,
    CONSTRAINT check_tmp_synthese_fix_cenpaca_count_max CHECK (count_max >= count_min),
	CONSTRAINT check_tmp_synthese_fix_cenpaca_date_max CHECK (date_max >= date_min),
    CONSTRAINT unique_tmp_synthese_fix_cenpaca_id_sinp UNIQUE (unique_id_sinp)
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set date style to ISO'
SET datestyle = 'ISO,DMY' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to fix temp table'
COPY gn_synthese.tmp_synthese_fix_cenpaca (
    unique_id_sinp,
    count_min,
    count_max,
    date_min,
    date_max,
    additional_data
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' QUOTE '#' ESCAPE '\';


\echo '-------------------------------------------------------------------------------'
\echo 'Create unique index on fix temp table for unique_id_sinp column'
CREATE UNIQUE INDEX IF NOT EXISTS idx_synthese_unique_id_sinp
    ON gn_synthese.tmp_synthese_fix_cenpaca
    USING btree(unique_id_sinp) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Change owner of fix temp table'
ALTER TABLE gn_synthese.tmp_synthese_fix_cenpaca OWNER TO geonatadmin ;

\echo '-------------------------------------------------------------------------------'
\echo 'Disable synthese trigger : meta dates change'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch update data into synthese'
DO $$
DECLARE
    step INTEGER := 99999 ;
    stopAt INTEGER := 4400000 ;
    offsetCnt INTEGER := 0 ;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in synthese table' ;
    WHILE offsetCnt < stopAt LOOP
        UPDATE gn_synthese.synthese AS s SET
            date_min = f.date_min,
            date_max = f.date_max,
            count_min = f.count_min,
            count_max = f.count_max,
            additional_data = f.additional_data
        FROM (
            SELECT
                unique_id_sinp,
                count_min,
                count_max,
                date_min,
                date_max,
                additional_data
            FROM gn_synthese.tmp_synthese_fix_cenpaca
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


\echo '-------------------------------------------------------------------------------'
\echo 'Enable "tri_meta_dates_change_synthese" trigger'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

\echo '-------------------------------------------------------------------------------'
\echo 'RUN this queries if necessary:'
\echo 'VACUUM FULL VERBOSE gn_synthese.synthese ;'
\echo 'ANALYSE VERBOSE gn_synthese.synthese ;'

COMMIT;
