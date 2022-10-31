-- Compute observations without corresponding area.
--
-- Transfert this script on server this way:
-- rsync -av ./01_* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/01_*


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations outside all'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_all;
CREATE TABLE gn_synthese.tmp_outside_all
AS
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_all_id_synthese_idx ON gn_synthese.tmp_outside_all (id_synthese);
CREATE INDEX tmp_outside_all_unique_id_sinp_idx ON gn_synthese.tmp_outside_all (unique_id_sinp);
CREATE INDEX tmp_outside_all_the_geom_local_idx ON gn_synthese.tmp_outside_all USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_all TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M10 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_m10;
CREATE TABLE gn_synthese.tmp_outside_m10
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('M10')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_m10_id_synthese_idx ON gn_synthese.tmp_outside_m10 (id_synthese);
CREATE INDEX tmp_outside_m10_unique_id_sinp_idx ON gn_synthese.tmp_outside_m10 (unique_id_sinp);
CREATE INDEX tmp_outside_m10_the_geom_local_idx ON gn_synthese.tmp_outside_m10 USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_m10 TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M5 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_m5;
CREATE TABLE gn_synthese.tmp_outside_m5
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('M5')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_m5_id_synthese_idx ON gn_synthese.tmp_outside_m5 (id_synthese);
CREATE INDEX tmp_outside_m5_unique_id_sinp_idx ON gn_synthese.tmp_outside_m5 (unique_id_sinp);
CREATE INDEX tmp_outside_m5_the_geom_local_idx ON gn_synthese.tmp_outside_m5 USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_m5 TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M1 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_m1;
CREATE TABLE gn_synthese.tmp_outside_m1
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('M1')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_m1_id_synthese_idx ON gn_synthese.tmp_outside_m1 (id_synthese);
CREATE INDEX tmp_outside_m1_unique_id_sinp_idx ON gn_synthese.tmp_outside_m1 (unique_id_sinp);
CREATE INDEX tmp_outside_m1_the_geom_local_idx ON gn_synthese.tmp_outside_m1 USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_m1 TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no Communes corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_com;
CREATE TABLE gn_synthese.tmp_outside_com
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('COM')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_com_id_synthese_idx ON gn_synthese.tmp_outside_com (id_synthese);
CREATE INDEX tmp_outside_com_unique_id_sinp_idx ON gn_synthese.tmp_outside_com (unique_id_sinp);
CREATE INDEX tmp_outside_com_the_geom_local_idx ON gn_synthese.tmp_outside_com USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_com TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no Départements corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_dep;
CREATE TABLE gn_synthese.tmp_outside_dep
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('DEP')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_dep_id_synthese_idx ON gn_synthese.tmp_outside_dep (id_synthese);
CREATE INDEX tmp_outside_dep_unique_id_sinp_idx ON gn_synthese.tmp_outside_dep (unique_id_sinp);
CREATE INDEX tmp_outside_dep_the_geom_local_idx ON gn_synthese.tmp_outside_dep USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_dep TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no PACA Départements corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_dep_paca;
CREATE TABLE gn_synthese.tmp_outside_dep_paca
AS
	WITH meshes AS (
		SELECT la.id_area
		FROM ref_geo.l_areas la
		WHERE la.id_type = ref_geo.get_id_area_type('DEP')
            AND la.area_code IN ('04', '05', '06', '13', '83', '84')
	)
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM gn_synthese.cor_area_synthese cas
			JOIN meshes m ON cas.id_area = m.id_area
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA;
CREATE INDEX tmp_outside_dep_paca_id_synthese_idx ON gn_synthese.tmp_outside_dep_paca (id_synthese);
CREATE INDEX tmp_outside_dep_paca_unique_id_sinp_idx ON gn_synthese.tmp_outside_dep_paca (unique_id_sinp);
CREATE INDEX tmp_outside_dep_paca_the_geom_local_idx ON gn_synthese.tmp_outside_dep_paca USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_dep_paca TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations outside SINP PACA territory'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_sinp;
CREATE TABLE gn_synthese.tmp_outside_sinp
AS
    SELECT
        s.id_synthese,
		s.unique_id_sinp,
		s.unique_id_sinp_grp,
		s.entity_source_pk_value,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_4326,
		s.the_geom_point,
		s.the_geom_local
    FROM gn_synthese.synthese AS s
    WHERE NOT EXISTS (
        SELECT 'X' FROM ref_geo.tmp_subdivided_sinp_area AS c
        WHERE public.st_intersects(c.geom, s.the_geom_local)
    )
WITH DATA;
CREATE INDEX tmp_outside_sinp_id_synthese_idx ON gn_synthese.tmp_outside_sinp (id_synthese);
CREATE INDEX tmp_outside_sinp_unique_id_sinp_idx ON gn_synthese.tmp_outside_sinp (unique_id_sinp);
CREATE INDEX tmp_outside_sinp_the_geom_local_idx ON gn_synthese.tmp_outside_sinp USING gist (the_geom_local);
DO
$do$
    BEGIN
        IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'gnreader') THEN
            GRANT SELECT ON TABLE gn_synthese.tmp_outside_sinp TO gnreader;
        END IF;
    END;
$do$ ;
COMMIT;
