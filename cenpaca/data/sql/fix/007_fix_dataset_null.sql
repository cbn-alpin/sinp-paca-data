\echo 'Fix id_dataset field set to NULL in synthese table.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/cenpaca/data/sql/fix/007_*

BEGIN;


SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '----------------------------------------------------------------------------'
\echo 'Update id_dataset previously set to NULL'
UPDATE gn_synthese.synthese AS s
SET id_dataset = sit.dataset_id
FROM (
    SELECT
        cs.unique_id_sinp,
        cs.dataset_id
    FROM gn_imports.cenpaca_20220208_synthese AS cs
        JOIN  gn_synthese.synthese AS ss
            ON (cs.unique_id_sinp = ss.unique_id_sinp)
    WHERE ss.id_dataset IS NULL
        AND cs.meta_last_action IN ('U', 'I')
    ORDER BY cs.gid ASC
) AS sit
WHERE s.id_source NOT IN (gn_synthese.get_id_source_by_name('Simethis'), gn_synthese.get_id_source_by_name('SI CBN'))
    AND s.id_dataset IS NULL
    AND s.unique_id_sinp = sit.unique_id_sinp ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean table gn_synthese.synthese '
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;
