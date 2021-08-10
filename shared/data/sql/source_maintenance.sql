\echo 'Maintenance on gn_synthese.t_sources tables after massive insert, update or delete.'
\echo 'Perform VACUUM FULL VERBOSE ANALYSE on table that will lock up.'
\echo 'Rights: dbowner'
\echo 'GeoNature database compatibility : v2.3.0+'

\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "gn_synthese.t_sources" => table locked !'
VACUUM FULL VERBOSE ANALYSE gn_synthese.t_sources ;
