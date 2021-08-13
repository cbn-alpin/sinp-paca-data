BEGIN;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = ON;
SET check_function_bodies = FALSE;
SET client_min_messages = warning;

CREATE SCHEMA IF NOT EXISTS imports;

SET search_path = imports, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = FALSE;

DROP SEQUENCE IF EXISTS synthese_id_synthese_seq CASCADE ;

CREATE SEQUENCE synthese_id_synthese_seq
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1
    NO CYCLE;

DROP TABLE IF EXISTS synthese_faune CASCADE ;

CREATE TABLE synthese_faune (
    id_synthese BIGINT DEFAULT NEXTVAL('synthese_id_synthese_seq'::regclass) NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    code_source CHARACTER VARYING(255),
    code_module CHARACTER VARYING(255),
    entity_source_pk_value CHARACTER VARYING(25),
    code_dataset CHARACTER VARYING(25),
    code_nomenclature_geo_object_nature CHARACTER VARYING(25),
    code_nomenclature_grp_typ CHARACTER VARYING(25),
    code_nomenclature_obs_meth CHARACTER VARYING(25),
    code_nomenclature_obs_technique CHARACTER VARYING(25),
    code_nomenclature_bio_status CHARACTER VARYING(25),
    code_nomenclature_bio_condition CHARACTER VARYING(25),
    code_nomenclature_naturalness CHARACTER VARYING(25),
    code_nomenclature_exist_proof CHARACTER VARYING(25),
    code_nomenclature_valid_status CHARACTER VARYING(25),
    code_nomenclature_diffusion_level CHARACTER VARYING(25),
    code_nomenclature_life_stage CHARACTER VARYING(25),
    code_nomenclature_sex CHARACTER VARYING(25),
    code_nomenclature_obj_count CHARACTER VARYING(25),
    code_nomenclature_type_count CHARACTER VARYING(25),
    code_nomenclature_sensitivity CHARACTER VARYING(25),
    code_nomenclature_observation_status CHARACTER VARYING(25),
    code_nomenclature_blurring CHARACTER VARYING(25),
    code_nomenclature_source_status CHARACTER VARYING(25),
    code_nomenclature_info_geo_type CHARACTER VARYING(25),
    count_min INTEGER,
    count_max INTEGER,
    cd_nom INTEGER,
    nom_cite CHARACTER VARYING(1000) NOT NULL,
    meta_v_taxref CHARACTER VARYING(50) NULL,
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min INTEGER,
    altitude_max INTEGER,
    geom_4326 public.geometry(Geometry,4326),
    geom_point public.geometry(Point,4326),
    geom_local public.geometry(Geometry,2154),
    date_min TIMESTAMP WITHOUT TIME zone NOT NULL,
    date_max TIMESTAMP WITHOUT TIME zone NOT NULL,
    validator CHARACTER VARYING(1000),
    validation_comment text,
    observers CHARACTER VARYING(1000),
    determiner CHARACTER VARYING(1000),
    id_digitiser INTEGER,
    code_nomenclature_determination_method CHARACTER VARYING(25),
    comment_context text,
    comment_description text,
    meta_validation_date TIMESTAMP WITHOUT TIME zone,
    meta_create_date TIMESTAMP WITHOUT TIME zone DEFAULT now(),
    meta_update_date TIMESTAMP WITHOUT TIME zone DEFAULT now(),
    last_action CHARACTER(1),
    CONSTRAINT check_synthese_altitude_max CHECK ((altitude_max >= altitude_min)),
    CONSTRAINT check_synthese_count_max CHECK ((count_max >= count_min)),
    CONSTRAINT check_synthese_date_max CHECK ((date_max >= date_min)),
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_dims_geom_point CHECK ((public.st_ndims(geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(geom_point) = 'POINT'::text) OR (geom_point IS NULL))),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = 2154)),
    CONSTRAINT enforce_srid_geom_point CHECK ((public.st_srid(geom_point) = 4326))
);

COPY synthese_faune (
    id_synthese,
    unique_id_sinp,
    unique_id_sinp_grp,
    code_source,
    code_module,
    entity_source_pk_value,
    code_dataset,
    code_nomenclature_geo_object_nature,
    code_nomenclature_grp_typ,
    code_nomenclature_obs_meth,
    code_nomenclature_obs_technique,
    code_nomenclature_bio_status,
    code_nomenclature_bio_condition,
    code_nomenclature_naturalness,
    code_nomenclature_exist_proof,
    code_nomenclature_valid_status,
    code_nomenclature_diffusion_level,
    code_nomenclature_life_stage,
    code_nomenclature_sex,
    code_nomenclature_obj_count,
    code_nomenclature_type_count,
    code_nomenclature_sensitivity,
    code_nomenclature_observation_status,
    code_nomenclature_blurring,
    code_nomenclature_source_status,
    code_nomenclature_info_geo_type,
    count_min,
    count_max,
    cd_nom,
    nom_cite,
    meta_v_taxref,
    sample_number_proof,
    digital_proof,
    non_digital_proof,
    altitude_min,
    altitude_max,
    geom_4326,
    geom_point,
    geom_local,
    date_min,
    date_max,
    validator,
    validation_comment,
    observers,
    determiner,
    id_digitiser,
    code_nomenclature_determination_method,
    comment_context,
    comment_description,
    meta_validation_date,
    meta_create_date,
    meta_update_date,
    last_action
)
FROM :'csvFilePath'
WITH DELIMITER E'\t' CSV HEADER NULL '\N' ;

ALTER TABLE ONLY synthese_faune
    ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY synthese_faune
    ADD CONSTRAINT unique_id_sinp_unique UNIQUE (unique_id_sinp);

CREATE INDEX i_synthese_altitude_max ON synthese_faune USING btree (altitude_max);

CREATE INDEX i_synthese_altitude_min ON synthese_faune USING btree (altitude_min);

CREATE INDEX i_synthese_cd_nom ON synthese_faune USING btree (cd_nom);

CREATE INDEX i_synthese_date_max ON synthese_faune USING btree (date_max DESC);

CREATE INDEX i_synthese_date_min ON synthese_faune USING btree (date_min DESC);

CREATE INDEX i_synthese_id_dataset ON synthese_faune USING btree (code_dataset);

CREATE INDEX i_synthese_t_sources ON synthese_faune USING btree (code_source);

CREATE INDEX i_synthese_geom_4326 ON synthese_faune USING gist (geom_4326);

CREATE INDEX i_synthese_geom_local ON synthese_faune USING gist (geom_local);

CREATE INDEX i_synthese_geom_point ON synthese_faune USING gist (geom_point);

COMMIT;
