\echo 'Set the_geom_point and the_geom_4326 with the_geom_local when they are empty.'
\echo 'Rights: owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/cenpaca/data/sql/fix/003_fix_geom.sql
BEGIN;

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

\echo '-------------------------------------------------------------------------------'
\echo 'Batch update geom into synthese'
DO $$
DECLARE
    step INTEGER := 100000 ;
    stopAt INTEGER := 1500000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER ;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in synthese table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % observations from %', step, offsetCnt ;

        UPDATE gn_synthese.synthese AS s SET
            the_geom_4326 = ST_Transform(st.the_geom_local, 4326),
            the_geom_point = ST_Transform(ST_Centroid(st.the_geom_local), 4326)
        FROM (
            SELECT unique_id_sinp, the_geom_local
            FROM gn_synthese.synthese
            WHERE the_geom_point IS NULL
                AND the_geom_4326 IS NULL
                AND the_geom_local IS NOT NULL
                AND the_geom_local != ''
            ORDER BY id_synthese ASC
            LIMIT step
            -- We query the same table that it's updated, so don't use OFFSET
            -- because it's eliminate previously updated rows.
            -- OFFSET offsetCnt
        ) AS st
        WHERE st.unique_id_sinp = s.unique_id_sinp ;

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
\echo 'RUN this queries if necessary:'
\echo 'VACUUM FULL VERBOSE gn_synthese.synthese ;'
\echo 'ANALYSE VERBOSE gn_synthese.synthese ;'

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
