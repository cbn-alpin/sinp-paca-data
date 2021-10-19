\echo 'Set precision fields in synthese table for fauna data where value is NULL.'
\echo 'These observations are attached to the municipality, so we use '
\echo 'the average radius of the municipality s area to define the precision.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/cenpaca/data/sql/fix/005_*

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Batch update precision into synthese'
DO $$
DECLARE
    step INTEGER := 100000 ;
    stopAt INTEGER := 450000 ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER ;
BEGIN
    RAISE NOTICE 'Start to loop on data to update in synthese table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to update % observations from %', step, offsetCnt ;

        UPDATE gn_synthese.synthese AS s SET
            "precision" = np.precision
        FROM (
            WITH municipalities AS (
                SELECT
                    la.id_area,
                    ROUND(AVG(st_distance(st_centroid(la.geom), com_points.geom))) AS "precision"
                FROM ref_geo.l_areas AS la
                    JOIN (
                        SELECT id_area, (st_dumpPoints(geom)).*
                        FROM ref_geo.l_areas
                        WHERE id_type = ref_geo.get_id_area_type('COM')
                            AND "enable" = TRUE
                    ) AS com_points
                        ON (la.id_area = com_points.id_area)
                WHERE la.id_type = ref_geo.get_id_area_type_by_code('COM')
                    AND la."enable" = TRUE
                GROUP BY la.id_area
            )
            SELECT
                unique_id_sinp,
                m."precision"
            FROM gn_synthese.synthese AS s
                LEFT JOIN gn_synthese.cor_area_synthese AS cas
                    ON (s.id_synthese = cas.id_synthese)
                JOIN municipalities AS m
                    ON (cas.id_area = m.id_area)
            WHERE s.id_source != gn_synthese.get_id_source_by_name('SI CBN')
                AND s."precision" IS NULL
            LIMIT step
            -- We query the same table that it's updated, so don't use OFFSET
            -- because it's eliminate previously updated rows.
            -- OFFSET offsetCnt
        ) AS np
        WHERE np.unique_id_sinp = s.unique_id_sinp
            AND s.id_source != gn_synthese.get_id_source_by_name('SI CBN')
            AND s."precision" IS NULL ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Updated synthese rows: %', affectedRows ;

        offsetCnt := offsetCnt + step ;
    END LOOP ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean table gn_synthese.synthese '
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;
