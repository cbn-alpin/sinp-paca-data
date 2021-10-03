-- Re-insert all meshes (M1, M5, M10), departements (DEP), municipalities (COM)
-- and SINP area in gn_synthese.cor_area_synthese table.
--
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./reload_cor_area_synthese.sql geonat@db-paca-sinp:~/data/shared/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/shared/data/sql/reload_cor_area_synthese.sql
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable triggers depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_maj_cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, disable trigger "tri_maj_cor_area_taxon"' ;
            ALTER TABLE gn_synthese.cor_area_synthese DISABLE TRIGGER tri_maj_cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_maj_cor_area_taxon" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_cor_area_taxon_update_cd_nom'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, disable trigger "tri_update_cor_area_taxon_update_cd_nom"' ;
            ALTER TABLE gn_synthese.cor_area_synthese DISABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_update_cor_area_taxon_update_cd_nom" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided DEP and COM areas table for faster cor_area_synthese reinsert'

\echo ' Remove subdivided DEP and COM areas table if necessary'
DROP TABLE IF EXISTS ref_geo.tmp_subdivided_areas ;

\echo ' Remove geom index on subdivided DEP and COM areas table'
DROP INDEX IF EXISTS ref_geo.idx_tmp_subdivided_areas ;

\echo ' Add subdivided DEP and COM areas table'
CREATE TABLE ref_geo.tmp_subdivided_areas AS
    SELECT
        random() AS gid,
        a.id_area AS area_id,
        st_subdivide(a.geom, 250) AS geom
    FROM ref_geo.l_areas AS a
    WHERE a."enable" = TRUE
        AND a.id_type IN (
            ref_geo.get_id_area_type('DEP'), -- Départements
            ref_geo.get_id_area_type('COM') -- Communes
        ) ;

\echo ' Create index on geom column for subdivided DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_geom ON ref_geo.tmp_subdivided_areas USING gist (geom);

\echo ' Create index on column id_area for subdivided DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_area_id ON ref_geo.tmp_subdivided_areas USING btree(area_id) ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all data in cor_area_synthese'

-- TRUNCATE TABLE cor_area_synthese ;
-- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below inserts

\echo ' Clean Départements and Communes in table cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('DEP'), -- Départements
        ref_geo.get_id_area_type('COM') -- Communes
    )
) ;

\echo ' Reinsert Départements and Communes'
-- ~35mn for ~1,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT DISTINCT
        s.id_synthese,
        a.area_id
    FROM gn_synthese.synthese AS s
        JOIN ref_geo.tmp_subdivided_areas AS a
            ON public.st_intersects(s.the_geom_local, a.geom) ;

\echo ' Clean Meshes (M1, M5, M10) in table cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('M1'), -- 1x1km meshes
        ref_geo.get_id_area_type('M5'), -- 5x5km meshes
        ref_geo.get_id_area_type('M10') -- 10x10km meshes
    )
) ;

\echo ' Reinsert for meshes'
-- ~3mn for ~35,000 areas and ~6,000,000 of rows in synthese table on SSD NVME disk
INSERT INTO gn_synthese.cor_area_synthese
    SELECT
        s.id_synthese,
        a.id_area
    FROM ref_geo.l_areas AS a
        JOIN gn_synthese.synthese AS s
            ON (a.geom && s.the_geom_local) -- Postgis operator && : https://postgis.net/docs/geometry_overlaps.html
    WHERE a.id_type IN (
        ref_geo.get_id_area_type('M10'), -- Mailles 10*10
        ref_geo.get_id_area_type('M5'), -- Mailles 5*5
        ref_geo.get_id_area_type('M1') -- Mailles 1*1
    ) ;

\echo ' Clean SINP area in table cor_area_synthese'
WITH sinp AS (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('SINP')
    LIMIT 1
)
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM sinp
) ;

\echo ' Reinsert all observations in cor_area_synthese link to SINP area'
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    WITH sinp AS (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type('SINP') -- SINP area
        LIMIT 1
    )
    SELECT
        s.id_synthese,
        sinp.id_area
    FROM gn_synthese.synthese AS s, sinp ;
-- ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;


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
            RAISE NOTICE ' For GeoNature < v2.6.0, enable trigger "tri_update_cor_area_taxon_update_cd_nom"' ;
            ALTER TABLE cor_area_synthese ENABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_update_cor_area_taxon_update_cd_nom" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
