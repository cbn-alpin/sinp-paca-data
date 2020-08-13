\echo 'Maintenance on gn_synthese tables after massive insert into synthese'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "synthese"'
VACUUM FULL VERBOSE gn_synthese.synthese ;
ANALYSE VERBOSE gn_synthese.synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_synthese"'
VACUUM FULL VERBOSE gn_synthese.cor_area_synthese ;
ANALYSE VERBOSE gn_synthese.cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_taxon"'
VACUUM FULL VERBOSE gn_synthese.cor_area_taxon ;
ANALYSE VERBOSE gn_synthese.cor_area_taxon ;
