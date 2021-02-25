\echo '-------------------------------------------------------------------------------'
\echo 'Deleting previously loaded data in synthese'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete previous data loaded in synthese from this sources'
DELETE FROM gn_synthese.synthese
WHERE id_source IN (
    SELECT gn_synthese.get_id_source_by_name(tmp.name_source)
    FROM gn_synthese.tmp_sources AS tmp
) OR id_source IS NULL ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT ;
