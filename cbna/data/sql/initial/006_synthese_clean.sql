\echo '-------------------------------------------------------------------------------'
\echo 'Deleting previously loaded data in synthese'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete previous data from same source'
DELETE FROM gn_synthese.synthese
WHERE id_source = gn_synthese.get_id_source('CBNA_EXPORT') ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
