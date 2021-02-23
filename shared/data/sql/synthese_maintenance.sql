\echo 'Maintenance on gn_synthese tables after massive insert into synthese'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.3.0+'

\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "synthese"'
VACUUM FULL VERBOSE gn_synthese.synthese ;
ANALYSE VERBOSE gn_synthese.synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_synthese"'
VACUUM FULL VERBOSE gn_synthese.cor_area_synthese ;
ANALYSE VERBOSE gn_synthese.cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, maintenance on "cor_area_taxon"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN
            VACUUM FULL VERBOSE gn_synthese.cor_area_taxon ;
            ANALYSE VERBOSE gn_synthese.cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;
