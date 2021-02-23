\echo 'Prepare database after deleting data into synthese'
\echo 'Rights: db owner'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Defines variables'
SET client_encoding = 'UTF8' ;
SET search_path = gn_synthese, public, pg_catalog ;


\echo '----------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, replay trigger "tri_del_area_synt_maj_corarea_tax" actions'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_del_area_synt_maj_corarea_tax'
        ) IS TRUE THEN
            RAISE NOTICE ' Deleting cor_area_synthese entries not linked with synthese' ;
            DELETE FROM cor_area_synthese AS cas
            WHERE NOT EXISTS (
                SELECT 'X'
                FROM synthese AS s
                WHERE s.id_synthese = cas.id_synthese
            ) ;

            RAISE NOTICE ' Clean table cor_area_taxon' ;
            TRUNCATE TABLE cor_area_taxon ;
            -- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below insert

            RAISE NOTICE ' Reinsert all data in cor_area_taxon' ;
            INSERT INTO cor_area_taxon (id_area, cd_nom, last_date, nb_obs)
                SELECT cor.id_area, s.cd_nom, MAX(s.date_min) AS last_date, COUNT(s.id_synthese) AS nb_obs
                FROM cor_area_synthese AS cor
                    JOIN synthese AS s
                        ON (s.id_synthese = cor.id_synthese)
                GROUP BY cor.id_area, s.cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.6.0 => trigger "tri_del_area_synt_maj_corarea_tax" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature < v2.3.2, replay and enable synthese trigger "trg_refresh_taxons_forautocomplete"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'taxons_synthese_autocomplete'
        ) IS TRUE THEN
            RAISE NOTICE ' Replay trigger action' ;
            DELETE FROM taxons_synthese_autocomplete AS tsa
            WHERE NOT EXISTS (
                SELECT DISTINCT ON (s.cd_nom) 'X'
                FROM synthese AS s
                WHERE s.cd_nom = tsa.cd_nom
            ) ;

            RAISE NOTICE ' Enable trigger' ;
            ALTER TABLE synthese ENABLE TRIGGER trg_refresh_taxons_forautocomplete ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.3.2 => trigger "trg_refresh_taxons_forautocomplete" not exists !' ;
        END IF ;
    END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, enable trigger "tri_del_area_synt_maj_corarea_tax"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_del_area_synt_maj_corarea_tax'
        ) IS TRUE THEN
            ALTER TABLE synthese ENABLE TRIGGER tri_del_area_synt_maj_corarea_tax ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.6.0 => trigger "tri_del_area_synt_maj_corarea_tax" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
