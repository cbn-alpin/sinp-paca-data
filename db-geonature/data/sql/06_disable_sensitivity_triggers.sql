-- Change sensitivity triggers functions to do nothing !
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
-- Transfert this script on server with Git or this way:
--      rsync -av ./06_* geonat@db-pacaa-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./06_*

\echo '-------------------------------------------------------------------------------'
\echo 'Drop & recreate trigger tri_insert_calculate_sensitivity on gn_synthese.synthese '
DROP TRIGGER IF EXISTS tri_insert_calculate_sensitivity ON gn_synthese.synthese ;

CREATE TRIGGER tri_insert_calculate_sensitivity
AFTER INSERT ON gn_synthese.synthese REFERENCING NEW TABLE AS NEW
FOR EACH STATEMENT EXECUTE FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement() ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop & recreate trigger tri_update_calculate_sensitivity on gn_synthese.synthese '
DROP TRIGGER IF EXISTS tri_update_calculate_sensitivity ON gn_synthese.synthese ;

CREATE TRIGGER tri_update_calculate_sensitivity
BEFORE UPDATE OF date_min, date_max, cd_nom, the_geom_local, id_nomenclature_bio_status, id_nomenclature_behaviour
ON gn_synthese.synthese
FOR EACH ROW EXECUTE FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row() ;


\echo '-------------------------------------------------------------------------------'
\echo 'Change gn_synthese.fct_tri_calculate_sensitivity_on_each_statement() to do nothing !'
CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
    -- Calculate sensitivity on insert in synthese: do nothing !
    BEGIN
    RETURN NULL;
    END;
    $function$
;


\echo '-------------------------------------------------------------------------------'
\echo 'Change gn_synthese.fct_tri_update_sensitivity_on_each_row() to do nothing !'
CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
    -- Calculate sensitivity on update in synthese: do nothing !
    BEGIN
    RETURN NEW;
    END;
    $function$
;
