\echo 'Prepare database before insert into synthese'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Defines variables'
SET client_encoding = 'UTF8' ;
SET search_path = gn_synthese, public, pg_catalog ;

\echo '-------------------------------------------------------------------------------'
\echo 'Update "synthese_id_synthese_seq" sequence'
SELECT SETVAL('synthese_id_synthese_seq', (SELECT MAX(id_synthese) FROM gn_synthese.synthese)) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop synthese primary key dependent constraints'
ALTER TABLE cor_area_synthese DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_synthese ;
ALTER TABLE cor_observer_synthese DROP CONSTRAINT IF EXISTS fk_gn_synthese_id_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop synthese primary key index'
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS pk_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop unique SINP id index on synthese'
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS unique_id_sinp_unique ;
DROP INDEX IF EXISTS unique_id_sinp_unique ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop other synthese indexes'
DROP INDEX IF EXISTS i_synthese_altitude_max ;
DROP INDEX IF EXISTS i_synthese_altitude_min ;
DROP INDEX IF EXISTS i_synthese_cd_nom ;
DROP INDEX IF EXISTS i_synthese_date_max ;
DROP INDEX IF EXISTS i_synthese_date_min ;
DROP INDEX IF EXISTS i_synthese_id_dataset ;
DROP INDEX IF EXISTS i_synthese_t_sources ;
DROP INDEX IF EXISTS i_synthese_the_geom_4326 ;
DROP INDEX IF EXISTS i_synthese_the_geom_local ;
DROP INDEX IF EXISTS i_synthese_the_geom_point ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop synthese foreign keys'
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_area_attachment ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_dataset ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_digitiser ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_module ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_bio_condition ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_bio_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_blurring ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_determination_method ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_diffusion_level ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_exist_proof ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_geo_object_nature ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_id_nomenclature_grp_typ ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_info_geo_type ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_life_stage ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_obj_count ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_obs_meth ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_obs_technique ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_observation_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_sensitivity ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_sex ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_source_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_type_count ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_valid_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_source ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop synthese other constraints'
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_altitude_max ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_bio_condition ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_bio_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_blurring ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_count_max ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_date_max ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_diffusion_level ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_exist_proof ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_geo_object_nature ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_info_geo_type_id_area_attachment ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_life_stage ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_naturalness ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_obj_count ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_obs_meth ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_obs_technique ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_observation_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_sensitivity ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_sex ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_source_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_typ_grp ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_type_count ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS check_synthese_valid_status ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_dims_the_geom_4326 ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_dims_the_geom_local ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_dims_the_geom_point ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_geotype_the_geom_point ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_srid_the_geom_4326 ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_srid_the_geom_local ;
ALTER TABLE synthese DROP CONSTRAINT IF EXISTS enforce_srid_the_geom_point ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable synthese triggers'
ALTER TABLE cor_area_synthese DISABLE TRIGGER tri_maj_cor_area_taxon ;
ALTER TABLE synthese DISABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
ALTER TABLE synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;
ALTER TABLE synthese DISABLE TRIGGER tri_insert_cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature v2.3.2 and below handle table "gn_synthese.taxons_synthese_autocomplete"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'taxons_synthese_autocomplete'
        ) THEN
            RAISE NOTICE ' Disable synthese trigger "trg_refresh_taxons_forautocomplete"' ;
            ALTER TABLE synthese DISABLE TRIGGER trg_refresh_taxons_forautocomplete ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.3.2 => table "gn_synthese.taxons_synthese_autocomplete" not present !' ;
        END IF ;
    END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
