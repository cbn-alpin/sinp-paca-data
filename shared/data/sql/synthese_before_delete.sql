\echo 'Prepare database before deleting data into synthese'
\echo 'Rights: db owner'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Defines variables'
SET client_encoding = 'UTF8' ;
SET search_path = gn_synthese, public, pg_catalog ;


\echo '----------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, disable trigger "tri_del_area_synt_maj_corarea_tax"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_del_area_synt_maj_corarea_tax'
        ) IS TRUE THEN
            ALTER TABLE synthese DISABLE TRIGGER tri_del_area_synt_maj_corarea_tax ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.6.0 => trigger "tri_del_area_synt_maj_corarea_tax" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature < v2.3.2, disable synthese trigger "trg_refresh_taxons_forautocomplete"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'taxons_synthese_autocomplete'
        ) IS TRUE THEN
            ALTER TABLE synthese DISABLE TRIGGER trg_refresh_taxons_forautocomplete ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.3.2 => trigger "trg_refresh_taxons_forautocomplete" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
