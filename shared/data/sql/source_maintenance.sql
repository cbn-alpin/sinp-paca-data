\echo 'Maintenance on gn_synthese.t_sources tables after massive insert, update or delete.'
\echo 'Perform VACUUM VERBOSE ANALYSE on table that will NOT be lock up.'
\echo 'Rights: dbowner'
\echo 'GeoNature database compatibility : v2.3.0+'

\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "gn_synthese.t_sources"'
VACUUM VERBOSE ANALYSE gn_synthese.t_sources ;

\echo '-------------------------------------------------------------------------------'
\echo 'Reindex "gn_synthese.t_sources"'
REINDEX TABLE gn_synthese.t_sources ;
