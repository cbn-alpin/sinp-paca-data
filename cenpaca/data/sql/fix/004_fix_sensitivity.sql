\echo 'Disable date and sensitivity triggers then update for row with meta_last_action = I:'
\echo 'id_nomenclature_sensititvity, id_nomenclature_diffusion_level, meta_create_date and meta_update_date.'
\echo 'Rights: owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: sed "s/\${syntheseImportTable}/cenpaca_20210701_synthese/g" "./004_fix_sensitivity.sql" | \
-- psql -h "localhost" -U geonatadmin -d geonature2db -f -
BEGIN;

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch update id_nomenclature_sensitivity into synthese with trigger disabled'
DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER ;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := gn_imports.computeImportTotal('gn_imports.${syntheseImportTable}', 'I') ;
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to update in synthese table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % observations from %', step, offsetCnt ;

        UPDATE gn_synthese.synthese AS s SET
            id_nomenclature_sensitivity = sit.id_nomenclature_sensitivity,
            id_nomenclature_diffusion_level = sit.id_nomenclature_diffusion_level,
            meta_create_date = sit.meta_create_date,
            meta_update_date = sit.meta_update_date
        FROM (
            SELECT
                unique_id_sinp,
                id_nomenclature_sensitivity,
                id_nomenclature_diffusion_level,
                meta_create_date,
                meta_update_date
            FROM gn_imports.${syntheseImportTable}
            WHERE meta_last_action = 'I'
            ORDER BY gid ASC
            LIMIT step
            OFFSET offsetCnt
        ) AS sit
        WHERE sit.unique_id_sinp = s.unique_id_sinp ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + step ;
    END LOOP ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;


\echo '-------------------------------------------------------------------------------'
\echo 'RUN this queries if necessary:'
\echo 'VACUUM FULL VERBOSE gn_synthese.synthese ;'
\echo 'ANALYSE VERBOSE gn_synthese.synthese ;'


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
