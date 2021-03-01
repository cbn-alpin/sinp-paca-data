\echo 'Restore database after inserting data into synthese'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Defines variables'
SET client_encoding = 'UTF8' ;
SET search_path = gn_synthese, public, pg_catalog ;

\echo '-------------------------------------------------------------------------------'
\echo 'Update "synthese_id_synthese_seq" sequence'
SELECT SETVAL('synthese_id_synthese_seq', (SELECT MAX(id_synthese) FROM synthese)) ;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature v2.4.1+ add constraints on "synthese.id_area_attachment" column'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_name='synthese' and column_name='id_area_attachment'
        ) IS TRUE THEN
            RAISE NOTICE ' Add "fk_synthese_id_area_attachment"' ;
            ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_area_attachment
                FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area)
                ON UPDATE CASCADE ;

            -- RAISE NOTICE ' Add "check_synthese_info_geo_type_id_area_attachment"' ;
            -- -- Seems remove in GN > 2.5.5
            -- ALTER TABLE synthese ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment
            --     CHECK (
            --         NOT (
            --             ((ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type))::text = '2'::text)
            --             AND
            --             (id_area_attachment IS NULL)
            --         )
            --     ) NOT VALID ;
        ELSE
      		RAISE NOTICE ' GeoNature < v2.4.1 => column "synthese.id_area_attachment" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'Restore foreign keys constraints on synthese'
ALTER TABLE synthese ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
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
    FOREIGN KEY (id_source) REFERENCES t_sources(id_source)
    ON UPDATE CASCADE ;

\echo '-------------------------------------------------------------------------------'
\echo 'Restore foreign keys constraints depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='cd_hab'
        ) IS TRUE THEN
            RAISE NOTICE ' Restore foreign keys constraints on synthese.cd_hab"' ;
            ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_cd_hab
            FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab)
            ON UPDATE CASCADE ;
        ELSE
      		RAISE NOTICE ' GeoNature <= v2.4.1 => column "cd_hab" not exists on table "gn_synthese.synthese" !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='id_nomenclature_biogeo_status'
        ) IS TRUE THEN
            RAISE NOTICE ' Restore foreign keys constraints on synthese.id_nomenclature_biogeo_status"' ;
            ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status
            FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
            ON UPDATE CASCADE ;
        ELSE
      		RAISE NOTICE ' GeoNature <= v2.5.2 => column "id_nomenclature_biogeo_status" not exists on table "gn_synthese.synthese" !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='id_nomenclature_obs_meth'
        ) IS TRUE THEN
            RAISE NOTICE ' Restore foreign keys constraints on synthese.id_nomenclature_obs_meth"' ;
            ALTER TABLE synthese ADD CONSTRAINT fk_synthese_id_nomenclature_obs_meth
            FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature)
            ON UPDATE CASCADE ;
        ELSE
      		RAISE NOTICE ' GeoNature >= v2.5.0 => column "id_nomenclature_obs_meth" not exists on table "gn_synthese.synthese" !' ;
        END IF ;
    END
$$ ;

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
\echo 'Restore other constraints depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='depth_max'
        ) IS TRUE THEN
            RAISE NOTICE ' Restore check constraints on synthese.depth_max"' ;
            ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_depth_max
            CHECK ((depth_max >= depth_min)) ;
        ELSE
      		RAISE NOTICE ' GeoNature <= v2.4.1 => column "depth_max" not exists on table "gn_synthese.synthese" !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='id_nomenclature_biogeo_status'
        ) IS TRUE THEN
            RAISE NOTICE ' Restore check constraint on synthese.id_nomenclature_biogeo_status"' ;
            ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_biogeo_status
            CHECK (
                ref_nomenclatures.check_nomenclature_type_by_mnemonique(
                    id_nomenclature_biogeo_status,
                    'STAT_BIOGEO'::character varying
                )
            ) NOT VALID ;
        ELSE
      		RAISE NOTICE ' GeoNature <= v2.5.2 => column "id_nomenclature_biogeo_status" not exists on table "gn_synthese.synthese" !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'synthese'
                AND column_name='id_nomenclature_obs_meth'
        ) IS TRUE THEN
            RAISE NOTICE ' GeoNature < v2.5.0, restore foreign keys constraints on synthese.id_nomenclature_obs_meth for METH_OBS' ;
            ALTER TABLE synthese ADD CONSTRAINT check_synthese_obs_meth
            CHECK (
                ref_nomenclatures.check_nomenclature_type_by_mnemonique(
                    id_nomenclature_obs_meth,
                    'METH_OBS'::character varying
                )
            ) NOT VALID ;

            RAISE NOTICE ' GeoNature < v2.5.0, restore foreign keys constraints on synthese.id_nomenclature_obs_technique for TECHNIQUE_OBS' ;
            ALTER TABLE synthese ADD CONSTRAINT check_synthese_obs_technique
            CHECK (
                ref_nomenclatures.check_nomenclature_type_by_mnemonique(
                    id_nomenclature_obs_technique,
                    'TECHNIQUE_OBS'::character varying
                )
            ) NOT VALID ;
        ELSE
      		RAISE NOTICE ' GeoNature >= v2.5.0, , restore foreign keys constraints on synthese.id_nomenclature_obs_technique for METH_OBS' ;
            ALTER TABLE synthese ADD CONSTRAINT check_synthese_obs_technique
            CHECK (
                ref_nomenclatures.check_nomenclature_type_by_mnemonique(
                    id_nomenclature_obs_technique,
                    'METH_OBS'::character varying
                )
            ) NOT VALID ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'Restore indexes on "synthese" BEFORE others triggers actions'
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
\echo 'Commit all (INDEXES, CONSTRAINTS) before replay triggers actions. COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature v2.3.2 and below handle table "gn_synthese.taxons_synthese_autocomplete"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'taxons_synthese_autocomplete'
        ) IS TRUE THEN
            RAISE NOTICE ' Replay actions on table "synthese" (trg_refresh_taxons_forautocomplete)' ;

            RAISE NOTICE '  Clean table taxons_synthese_autocomplete' ;
            TRUNCATE TABLE taxons_synthese_autocomplete ;

            RAISE NOTICE '  Reinsert scientific names in table taxons_synthese_autocomplete' ;
            INSERT INTO taxons_synthese_autocomplete
                SELECT DISTINCT
                    t.cd_nom,
                    t.cd_ref,
                    CONCAT(t.lb_nom, ' = <i>', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']') AS search_name,
                    t.nom_valide,
                    t.lb_nom,
                    t.regne,
                    t.group2_inpn
                FROM synthese AS s
                    JOIN taxonomie.taxref AS t
                        ON (t.cd_nom = s.cd_nom) ;

            RAISE NOTICE '  Reinsert vernacular names in table taxons_synthese_autocomplete' ;
            INSERT INTO taxons_synthese_autocomplete
                SELECT DISTINCT
                    t.cd_nom,
                    t.cd_ref,
                    CONCAT(t.nom_vern, ' =  <i> ', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']' ) AS search_name,
                    t.nom_valide,
                    t.lb_nom,
                    t.regne,
                    t.group2_inpn
                FROM synthese AS s
                    JOIN taxonomie.taxref AS t
                        ON (t.cd_nom = s.cd_nom AND t.cd_nom = t.cd_ref)
                WHERE t.nom_vern IS NOT NULL ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.3.2 => table "gn_synthese.taxons_synthese_autocomplete" not exists !' ;
        END IF ;
    END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replay actions on table "synthese" (tri_meta_dates_change_synthese)'

\echo ' Update meta dates on "synthese" --> DO NOTHING !'
-- WARNING : Don't update this meta date fields to for future update script !
-- UPDATE synthese SET meta_create_date = NOW() WHERE meta_create_date IS NULL ;
-- UPDATE synthese SET meta_update_date = NOW() WHERE meta_update_date IS NULL ;

\echo '-------------------------------------------------------------------------------'
\echo 'Replay actions on table "cor_area_synthese" (triggers on it must be disabled !)'

\echo ' Clean table cor_area_synthese'
TRUNCATE TABLE cor_area_synthese ;
-- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below inserts

\echo ' Reinsert all data in cor_area_synthese for Départements and Communes'
-- ~35mn for ~1,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO cor_area_synthese
    SELECT
        s.id_synthese,
        a.id_area
    FROM ref_geo.l_areas AS a
        JOIN synthese AS s
            ON public.st_intersects(s.the_geom_local, a.geom)
    WHERE a.id_type IN (
        ref_geo.get_id_area_type('DEP'), -- Départements
        ref_geo.get_id_area_type('COM') -- Communes
    ) ;

\echo ' Reinsert all data in cor_area_synthese for meshes'
-- ~3mn for ~35,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO cor_area_synthese
    SELECT
        s.id_synthese,
        a.id_area
    FROM ref_geo.l_areas AS a
        JOIN synthese AS s
            ON (a.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE a.id_type IN (
        ref_geo.get_id_area_type('M10'), -- Mailles 10*10
        ref_geo.get_id_area_type('M5'), -- Mailles 5*5
        ref_geo.get_id_area_type('M1') -- Mailles 1*1
    ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, replay actions on table "cor_area_taxon" (play after cor_area_synthese trigger)'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN
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
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature > v2.5.5, replay action calculate sensitivity'
\echo 'WARNING : not replay for SINP PACA !'
-- DO $$
--     BEGIN
--         IF EXISTS (
--             SELECT 1
--             FROM pg_trigger
--             WHERE tgname = 'tri_insert_calculate_sensitivity'
--         ) IS TRUE THEN
--             RAISE NOTICE ' For GeoNature > v2.5.5, replay "tri_insert_calculate_sensitivity" action' ;
--             WITH cte AS (
--                 SELECT
--                     gn_sensitivity.get_id_nomenclature_sensitivity (
--                         inserted_rows.date_min::date,
--                         taxonomie.find_cdref(inserted_rows.cd_nom),
--                         inserted_rows.the_geom_local,
--                         ('{"STATUT_BIO": ' || inserted_rows.id_nomenclature_bio_status::text || '}')::jsonb
--                     ) AS id_nomenclature_sensitivity,
--                     id_synthese,
--                     t_diff.cd_nomenclature AS cd_nomenclature_diffusion_level
--                 FROM gn_synthese.synthese AS inserted_rows
--                     LEFT JOIN ref_nomenclatures.t_nomenclatures AS t_diff
--                     ON t_diff.id_nomenclature = inserted_rows.id_nomenclature_diffusion_level
--                 WHERE inserted_rows.id_nomenclature_sensitivity IS NULL
--             )
--             UPDATE gn_synthese.synthese AS s
--             SET
--                 id_nomenclature_sensitivity = c.id_nomenclature_sensitivity,
--                 id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
--                     'NIV_PRECIS',
--                     gn_sensitivity.calculate_cd_diffusion_level(
--                         c.cd_nomenclature_diffusion_level,
--                         t_sensi.cd_nomenclature
--                     )
--                 )
--             FROM cte AS c
--                 LEFT JOIN ref_nomenclatures.t_nomenclatures AS t_sensi
--                     ON t_sensi.id_nomenclature = c.id_nomenclature_sensitivity
--             WHERE c.id_synthese = s.id_synthese ;
--         ELSE
--       		RAISE NOTICE ' GeoNature < v2.6.0 => no replay action !' ;
--         END IF ;
--     END
-- $$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'Enable all triggers after replayed their actions'

\echo ' Enable "tri_meta_dates_change_synthese" trigger'
ALTER TABLE synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

\echo ' Enable "tri_insert_cor_area_synthese" trigger'
ALTER TABLE synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Enable triggers depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_maj_cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, enable "tri_maj_cor_area_taxon" trigger' ;
            ALTER TABLE cor_area_synthese ENABLE TRIGGER tri_maj_cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_maj_cor_area_taxon" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_cor_area_taxon_update_cd_nom'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, enable "tri_update_cor_area_taxon_update_cd_nom" trigger' ;
            ALTER TABLE synthese ENABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_update_cor_area_taxon_update_cd_nom" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_cor_area_synthese'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature > v2.5.5, enable trigger "tri_update_cor_area_synthese"' ;
            ALTER TABLE synthese ENABLE TRIGGER tri_update_cor_area_synthese ;
        ELSE
      		RAISE NOTICE ' GeoNature < v2.6.0 => trigger "tri_update_cor_area_synthese" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_insert_calculate_sensitivity'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature > v2.5.5, enable trigger "tri_insert_calculate_sensitivity"' ;
            ALTER TABLE synthese ENABLE TRIGGER tri_insert_calculate_sensitivity ;
        ELSE
      		RAISE NOTICE ' GeoNature < v2.6.0 => trigger "tri_insert_calculate_sensitivity" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_calculate_sensitivity'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature > v2.5.5, enable trigger "tri_update_calculate_sensitivity"' ;
            ALTER TABLE synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;
        ELSE
      		RAISE NOTICE ' GeoNature < v2.6.0 => trigger "tri_update_calculate_sensitivity" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'taxons_synthese_autocomplete'
        ) IS TRUE THEN
            RAISE NOTICE 'For GeoNature < v2.3.2, enable "trg_refresh_taxons_forautocomplete"' ;
            ALTER TABLE synthese ENABLE TRIGGER trg_refresh_taxons_forautocomplete ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.3.2 => table "gn_synthese.taxons_synthese_autocomplete" not exists !' ;
        END IF ;
    END
$$ ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
