\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "synthese"'
VACUUM FULL VERBOSE synthese ;
ANALYSE VERBOSE synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_synthese"'
VACUUM FULL VERBOSE cor_area_synthese ;
ANALYSE VERBOSE cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_taxon"'
VACUUM FULL VERBOSE cor_area_taxon ;
ANALYSE VERBOSE cor_area_taxon ;
