-- Droits d'éxecution nécessaire : SUPER UTILISATEUR
-- Remove useless areas from l_areas
-- TODO: check speed with constraint fk_li_municipalities_id_area and fk_li_grids_id_area enable or not

BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Disable Foreigns Keys of "l_areas" to speed the deleting'
ALTER TABLE ref_geo.l_areas DROP CONSTRAINT IF EXISTS fk_l_areas_id_type ;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT IF EXISTS fk_li_municipalities_id_area ;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT IF EXISTS fk_li_grids_id_area ;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_area_attachment ;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_area ;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT IF EXISTS fk_cor_site_area_id_area ;
ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT IF EXISTS fk_cor_sensitivity_area_id_area_fkey ;


\echo '----------------------------------------------------------------------------'
\echo 'Disabling Foreigns Keys of "l_areas" on "cor_area_taxon" table...'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN

            RAISE NOTICE ' Drop foreign key between "l_areas" and "cor_area_taxon"' ;
            ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT IF EXISTS fk_cor_area_taxon_id_area ;

        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;

\echo '--------------------------------------------------------------------------------'
\echo 'Drop "l_areas" primary key'
ALTER TABLE ref_geo.l_areas DROP CONSTRAINT IF EXISTS pk_l_areas ;


\echo '--------------------------------------------------------------------------------'
\echo 'Drop "l_areas" indexes not used by deleting'
DROP INDEX IF EXISTS ref_geo.index_l_areas_centroid ;


\echo '----------------------------------------------------------------------------'
\echo 'Delete areas not intersect with SINP area'
DELETE FROM ref_geo.l_areas AS a
WHERE NOT EXISTS (
   SELECT 'X' FROM :areaSubdividedTableName AS c
   WHERE public.st_intersects(c.geom, a.geom)
) ;

\echo '--------------------------------------------------------------------------------'
\echo 'Restore indexes'
CREATE INDEX IF NOT EXISTS index_l_areas_centroid ON ref_geo.l_areas USING gist (centroid) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Restore "l_areas" primary key index'
ALTER TABLE ref_geo.l_areas ADD CONSTRAINT pk_l_areas PRIMARY KEY (id_area) ;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on "li_municipalities" entries before deleting'
CREATE INDEX IF NOT EXISTS idx_li_municipalities_id_area ON ref_geo.li_municipalities USING btree (id_area) ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete useless "li_municipalities" entries'
DELETE FROM ref_geo.li_municipalities AS lm
WHERE NOT EXISTS (
   SELECT 'X' FROM ref_geo.l_areas AS la
   WHERE la.id_area = lm.id_area
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove index on "li_municipalities" entries after deleting'
DROP INDEX IF EXISTS ref_geo.idx_li_municipalities_id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on "li_grids" entries before deleting'
CREATE INDEX IF NOT EXISTS idx_li_grids_id_area ON ref_geo.li_grids USING btree (id_area) ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete useless "li_grids" entries'
DELETE FROM ref_geo.li_grids AS lg
WHERE NOT EXISTS (
   SELECT 'X' FROM ref_geo.l_areas AS la
   WHERE la.id_area = lg.id_area
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove index on "li_grids" entries after deleting'
DROP INDEX IF EXISTS ref_geo.idx_li_grids_id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on "cor_area_synthese" entries before deleting'
CREATE INDEX IF NOT EXISTS idx_cor_area_synthese_id_area ON gn_synthese.cor_area_synthese USING btree (id_area) ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete useless "cor_area_synthese" entries'
DELETE FROM gn_synthese.cor_area_synthese AS cas
WHERE NOT EXISTS (
   SELECT 'X' FROM ref_geo.l_areas AS la
   WHERE la.id_area = cas.id_area
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove index on "cor_area_synthese" entries after deleting'
DROP INDEX IF EXISTS gn_synthese.idx_cor_area_synthese_id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'Deleting useless "cor_area_taxon" entries...'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN

            RAISE NOTICE ' Create index on "cor_area_taxon" entries before deleting' ;
            CREATE INDEX IF NOT EXISTS  idx_cor_area_taxon_id_area ON gn_synthese.cor_area_taxon USING btree (id_area) ;

            RAISE NOTICE ' Delete useless "cor_area_taxon" entries' ;
            DELETE FROM gn_synthese.cor_area_taxon AS cat
            WHERE NOT EXISTS (
                SELECT 'X' FROM ref_geo.l_areas AS la
                WHERE  la.id_area = cat.id_area
            ) ;

            RAISE NOTICE ' Remove index on "cor_area_taxon" entries after deleting' ;
            DROP INDEX IF EXISTS gn_synthese.idx_cor_area_taxon_id_area ;

        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on "cor_sensitivity_area" entries before deleting'
CREATE INDEX IF NOT EXISTS idx_cor_sensitivity_area_id_area ON gn_sensitivity.cor_sensitivity_area USING btree (id_area) ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete useless "cor_sensitivity_area" entries'
DELETE FROM gn_sensitivity.cor_sensitivity_area AS csa
WHERE NOT EXISTS (
   SELECT 'X' FROM ref_geo.l_areas AS la
   WHERE la.id_area = csa.id_area
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove index on "cor_sensitivity_area" entries after deleting'
DROP INDEX IF EXISTS gn_sensitivity.idx_cor_sensitivity_area_id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on "cor_site_area" entries before deleting'
CREATE INDEX IF NOT EXISTS idx_cor_site_area_id_area ON gn_monitoring.cor_site_area USING btree (id_area) ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete useless "cor_site_area" entries'
DELETE FROM gn_monitoring.cor_site_area AS csa
WHERE NOT EXISTS (
   SELECT 'X' FROM ref_geo.l_areas AS la
   WHERE la.id_area = csa.id_area
) ;

\echo '----------------------------------------------------------------------------'
\echo 'Remove index on "cor_site_area" entries after deleting'
DROP INDEX IF EXISTS gn_monitoring.idx_cor_site_area_id_area ;


\echo '--------------------------------------------------------------------------------'
\echo 'Enable Foreigns Keys of "l_areas"'
ALTER TABLE ref_geo.l_areas ADD CONSTRAINT fk_l_areas_id_type
    FOREIGN KEY (id_type) REFERENCES ref_geo.bib_areas_types(id_type)
    ON UPDATE CASCADE ;

ALTER TABLE ref_geo.li_municipalities ADD CONSTRAINT fk_li_municipalities_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE
    ON DELETE CASCADE ;

ALTER TABLE ref_geo.li_grids ADD CONSTRAINT fk_li_grids_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE
    ON DELETE CASCADE  ;

ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_id_area_attachment
    FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE ;

ALTER TABLE gn_synthese.cor_area_synthese ADD CONSTRAINT fk_cor_area_synthese_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE ;

ALTER TABLE gn_sensitivity.cor_sensitivity_area ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;

ALTER TABLE gn_monitoring.cor_site_area ADD CONSTRAINT fk_cor_site_area_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;


\echo '----------------------------------------------------------------------------'
\echo 'Enabling Foreigns Keys of "l_areas" on "cor_area_taxon" table...'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN

            RAISE NOTICE ' Add foreign key between "l_areas" and "cor_area_taxon"' ;
            ALTER TABLE gn_synthese.cor_area_taxon ADD CONSTRAINT fk_cor_area_taxon_id_area
                FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
                ON UPDATE CASCADE ;

        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "synthese"'
VACUUM FULL VERBOSE ref_geo.l_areas ;
ANALYSE VERBOSE ref_geo.l_areas ;
