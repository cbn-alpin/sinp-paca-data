\echo 'Update synthese table with data store in temporary table.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -v csvFilePath="<path-to-csv-to-import>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "admin" -d "geonature2db" -v csvFilePath="/home/geonat/data/cbna-cbnmed/data/raw/synthese.fix-2022-03-29.csv" -f ~/data/cbna-cbnmed/data/sql/fix/001_fix_uuid.sql
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove table tmp_synthese_fix_cbnacbmed if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_synthese_fix_cbnacbmed ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create temp table to store synthese fix' ;
CREATE TABLE gn_synthese.tmp_synthese_fix_cbnacbmed (
    gid SERIAL PRIMARY KEY,
    unique_id_sinp uuid NULL,
    entity_source_pk_value VARCHAR NULL
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set date style to ISO'
SET datestyle = 'ISO,DMY' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to fix temp table'
COPY gn_synthese.tmp_synthese_fix_cbnacbmed (
    unique_id_sinp,
    entity_source_pk_value
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' QUOTE '#' ESCAPE '\';


\echo '-------------------------------------------------------------------------------'
\echo 'Create unique index on fix temp table for unique_id_sinp column'
CREATE UNIQUE INDEX IF NOT EXISTS idx_tmp_synthese_fix_cbnacbnmed_unique_id_sinp
    ON gn_synthese.tmp_synthese_fix_cbnacbmed
    USING btree(unique_id_sinp) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create unique index on fix temp table for entity_source_pk_value column'
CREATE UNIQUE INDEX IF NOT EXISTS idx_tmp_synthese_fix_cbnacbnmed_entity_source_pk_value
    ON gn_synthese.tmp_synthese_fix_cbnacbmed
    USING btree(entity_source_pk_value) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Change owner of fix temp table'
ALTER TABLE gn_synthese.tmp_synthese_fix_cbnacbmed OWNER TO geonatadmin ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add index on synthese for entity_source_pk_value column'
CREATE INDEX IF NOT EXISTS idx_synthese_entity_source_pk_value
    ON gn_synthese.synthese
    USING btree(entity_source_pk_value) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable synthese trigger : meta dates change'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '-------------------------------------------------------------------------------'
\echo 'Delete duplicate synthese rows based on entity_source_pk_value'
DELETE FROM gn_synthese.synthese
WHERE id_synthese IN (
    SELECT MAX(id_synthese) AS id_synthese
    FROM gn_synthese.synthese
    WHERE entity_source_pk_value NOT ILIKE '%\_%'
    GROUP BY entity_source_pk_value
    HAVING COUNT(unique_id_sinp) > 1
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch update data into synthese'
DO $$
DECLARE
    step INTEGER;
    stopAt INTEGER;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    SELECT COUNT(*) INTO stopAt FROM gn_synthese.tmp_synthese_fix_cbnacbmed ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update UUID in "synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % observations from %', step, offsetCnt ;

        UPDATE gn_synthese.synthese AS s SET
            unique_id_sinp = f.unique_id_sinp
        FROM (
            SELECT
                unique_id_sinp,
                entity_source_pk_value
            FROM gn_synthese.tmp_synthese_fix_cbnacbmed As tsfc
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS f
        WHERE s.entity_source_pk_value NOT ILIKE '%\_%'
            AND f.entity_source_pk_value = s.entity_source_pk_value ;
            -- Avoid using meta_update_date because it's not always correct.
            -- AND sit.meta_update_date > s.meta_update_date ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable "tri_meta_dates_change_synthese" trigger'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop index on synthese for entity_source_pk_value column'
DROP INDEX IF EXISTS gn_synthese.idx_synthese_entity_source_pk_value ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean table gn_synthese.synthese '
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;
