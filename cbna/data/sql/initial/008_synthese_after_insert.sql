\echo 'Restore database after insert into synthese'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Defines variables'
SET client_encoding = 'UTF8';
SET search_path = gn_synthese, public, pg_catalog;


\echo '-------------------------------------------------------------------------------'
\echo 'Update "synthese_id_synthese_seq" sequence'
SELECT SETVAL('synthese_id_synthese_seq', (SELECT MAX(id_synthese) FROM synthese)) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Restore foreign keys constraints on synthese'
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_area_attachment
    FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_dataset
    FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_digitiser
    FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_module
    FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_bio_condition
    FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_bio_status
    FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_blurring
    FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_determination_method
    FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_diffusion_level
    FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_exist_proof
    FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_geo_object_nature
    FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_id_nomenclature_grp_typ
    FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_info_geo_type
    FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_life_stage
    FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_obj_count
    FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_obs_meth
    FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_obs_technique
    FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_observation_status
    FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_sensitivity
    FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_sex
    FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_source_status
    FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_type_count
    FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_valid_status
    FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
    ON UPDATE CASCADE ;
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_source
    FOREIGN KEY (id_source) REFERENCES gn_synthese.t_sources(id_source)
    ON UPDATE CASCADE ;


\echo '-------------------------------------------------------------------------------'
\echo 'Restore other constraints on synthese'
ALTER TABLE synthese ADD CONSTRAINT check_synthese_altitude_max
    CHECK ((altitude_max >= altitude_min)) ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_bio_condition
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_bio_condition,
            'ETA_BIO'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_bio_status
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_bio_status,
            'STATUT_BIO'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_blurring
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_blurring,
            'DEE_FLOU'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_count_max
    CHECK ((count_max >= count_min)) ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_date_max
    CHECK ((date_max >= date_min)) ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_diffusion_level
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_diffusion_level,
            'NIV_PRECIS'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_exist_proof
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_exist_proof,
            'PREUVE_EXIST'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_geo_object_nature
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_geo_object_nature,
            'NAT_OBJ_GEO'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment
    CHECK (
        NOT (
            ((ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type))::text = '2'::text)
            AND
            (id_area_attachment IS NULL)
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_life_stage
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_life_stage,
            'STADE_VIE'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_naturalness
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_naturalness,
            'NATURALITE'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_obj_count
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_obj_count,
            'OBJ_DENBR'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_obs_meth
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_obs_meth,
            'METH_OBS'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_obs_technique
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_obs_technique,
            'TECHNIQUE_OBS'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_observation_status
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_observation_status,
            'STATUT_OBS'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_sensitivity
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_sensitivity,
            'SENSIBILITE'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_sex
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_sex,
            'SEXE'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_source_status
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_source_status,
            'STATUT_SOURCE'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_typ_grp
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_grp_typ,
            'TYP_GRP'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_type_count
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_type_count,
            'TYP_DENBR'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT check_synthese_valid_status
    CHECK (
        ref_nomenclatures.check_nomenclature_type_by_mnemonique(
            id_nomenclature_valid_status,
            'STATUT_VALID'::character varying
        )
    ) NOT VALID ;
ALTER TABLE synthese ADD CONSTRAINT enforce_dims_the_geom_4326
    CHECK ((st_ndims(the_geom_4326) = 2)) ;
ALTER TABLE synthese ADD CONSTRAINT enforce_dims_the_geom_local
    CHECK ((st_ndims(the_geom_local) = 2)) ;
ALTER TABLE synthese ADD CONSTRAINT enforce_dims_the_geom_point
    CHECK ((st_ndims(the_geom_point) = 2)) ;
ALTER TABLE synthese ADD CONSTRAINT enforce_geotype_the_geom_point
    CHECK (
        (
            (geometrytype(the_geom_point) = 'POINT'::text)
            OR
            (the_geom_point IS NULL)
        )
    ) ;
ALTER TABLE synthese ADD CONSTRAINT enforce_srid_the_geom_4326
    CHECK ((st_srid(the_geom_4326) = 4326)) ;

ALTER TABLE synthese ADD CONSTRAINT enforce_srid_the_geom_local
    CHECK ((st_srid(the_geom_local) = 2154)) ;
ALTER TABLE synthese ADD CONSTRAINT enforce_srid_the_geom_point
    CHECK ((st_srid(the_geom_point) = 4326)) ;
ALTER TABLE synthese ADD CONSTRAINT pk_synthese
     PRIMARY KEY (id_synthese) ;
ALTER TABLE synthese ADD CONSTRAINT unique_id_sinp_unique
    UNIQUE (unique_id_sinp) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Restore indexes on "synthese" AFTER maintenance (vacuum) and BEFORE others triggers actions'
CREATE INDEX IF NOT EXISTS i_synthese_altitude_max ON synthese USING btree(altitude_max) ;
CREATE INDEX IF NOT EXISTS i_synthese_altitude_min ON synthese USING btree(altitude_min) ;
CREATE INDEX IF NOT EXISTS i_synthese_cd_nom ON synthese USING btree(cd_nom) ;
CREATE INDEX IF NOT EXISTS i_synthese_date_min ON synthese USING btree(date_min DESC) ;
CREATE INDEX IF NOT EXISTS i_synthese_date_max ON synthese USING btree(date_max DESC) ;
CREATE INDEX IF NOT EXISTS i_synthese_id_dataset ON synthese USING btree(id_dataset) ;
CREATE INDEX IF NOT EXISTS i_synthese_t_sources ON synthese USING btree(id_source) ;
CREATE INDEX IF NOT EXISTS i_synthese_the_geom_4326 ON synthese USING gist(the_geom_4326) ;
CREATE INDEX IF NOT EXISTS i_synthese_the_geom_local ON synthese USING gist(the_geom_local) ;
CREATE INDEX IF NOT EXISTS i_synthese_the_geom_point ON synthese USING gist(the_geom_point) ;
-- CREATE UNIQUE INDEX IF NOT EXISTS pk_synthese ON synthese USING btree(id_synthese) ;
-- CREATE UNIQUE INDEX IF NOT EXISTS unique_id_sinp_unique ON synthese USING btree(unique_id_sinp) ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Replay actions on table "synthese" (tri_meta_dates_change_synthese)'

\echo ' Update meta dates on "synthese"'
UPDATE synthese SET meta_create_date = NOW() WHERE meta_create_date IS NULL ;
UPDATE synthese SET meta_update_date = NOW() WHERE meta_update_date IS NULL ;

\echo ' Enable "tri_meta_dates_change_synthese" trigger'
ALTER TABLE synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replay actions on table "cor_area_taxon" (tri_update_cor_area_taxon_update_cd_nom & tri_maj_cor_area_taxon)'

\echo ' Clean table cor_area_taxon'
TRUNCATE TABLE cor_area_taxon ;

\echo ' Reinsert all data in cor_area_taxon'
INSERT INTO gn_synthese.cor_area_taxon (id_area, cd_nom, last_date, nb_obs)
    SELECT id_area, s.cd_nom, MAX(s.date_min) AS last_date, COUNT(s.id_synthese) AS nb_obs
    FROM gn_synthese.cor_area_synthese AS cor
        JOIN gn_synthese.synthese AS s
            ON s.id_synthese = cor.id_synthese
    GROUP BY id_area, s.cd_nom ;

\echo ' Enable "tri_maj_cor_area_taxon" & "tri_update_cor_area_taxon_update_cd_nom" triggers'
ALTER TABLE cor_area_synthese ENABLE TRIGGER tri_maj_cor_area_taxon ;
ALTER TABLE synthese ENABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replay actions on table "cor_area_synthese" (tri_insert_cor_area_synthese)'

\echo ' Clean table cor_area_synthese'
TRUNCATE TABLE cor_area_synthese ;

\echo ' Reinsert all data in cor_area_synthese'
INSERT INTO cor_area_synthese
    SELECT
        s.id_synthese,
        a.id_area
    FROM ref_geo.l_areas AS a
        JOIN gn_synthese.synthese AS s
            ON public.st_intersects(s.the_geom_local, a.geom)
    WHERE a.enable = true ;

\echo ' Enable "tri_insert_cor_area_synthese" trigger'
ALTER TABLE synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;