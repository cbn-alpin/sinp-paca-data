\echo 'Maintenance on gn_synthese tables after massive insert into synthese.'
\echo 'Perform VACUUM VERBOSE ANALYSE on multiple tables that will NOT be lock up.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.3.0+'

\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "synthese"'
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Reindex "synthese"'
REINDEX TABLE gn_synthese.synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "cor_area_synthese"'
VACUUM VERBOSE ANALYSE gn_synthese.cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Reindex "cor_area_synthese"'
REINDEX TABLE gn_synthese.cor_area_synthese ;


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
            VACUUM VERBOSE ANALYSE gn_synthese.cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;
