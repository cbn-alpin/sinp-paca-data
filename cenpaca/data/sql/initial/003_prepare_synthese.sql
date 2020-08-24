\echo '-------------------------------------------------------------------------------'
\echo 'Deleting previously loaded data in synthese'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete previous data loaded in synthese from this sources'
DELETE FROM gn_synthese.synthese
WHERE id_source IN (
    SELECT gn_synthese.get_id_source(tmp.name_source)
    FROM temp_sources AS tmp
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
