-- Add tables with observations not linked to geom after insert not existing geom.
--
-- Transfert this script on server this way:
-- rsync -av ./05_* geonat@db-paca-sinp:~/data/outside/data/sql/update/ --dry-run
--
-- Use this script this way:
-- psql -h localhost -U geonatadmin -d geonature2db -f ~/data/outside/data/sql/update/05_*



\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_all;
CREATE TABLE gn_synthese.tmp_outside_after_all
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
CREATE INDEX tmp_outside_after_all_id_synthese_idx ON gn_synthese.tmp_outside_after_all (id_synthese);
CREATE INDEX tmp_outside_after_all_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_all (unique_id_sinp);
CREATE INDEX tmp_outside_after_all_the_geom_local_idx ON gn_synthese.tmp_outside_after_all USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_all TO gnreader;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M10 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_m10;
CREATE TABLE gn_synthese.tmp_outside_after_m10
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
CREATE INDEX tmp_outside_after_m10_id_synthese_idx ON gn_synthese.tmp_outside_after_m10 (id_synthese);
CREATE INDEX tmp_outside_after_m10_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_m10 (unique_id_sinp);
CREATE INDEX tmp_outside_after_m10_the_geom_local_idx ON gn_synthese.tmp_outside_after_m10 USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_m10 TO gnreader;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M5 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_m5;
CREATE TABLE gn_synthese.tmp_outside_after_m5
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
CREATE INDEX tmp_outside_after_m5_id_synthese_idx ON gn_synthese.tmp_outside_after_m5 (id_synthese);
CREATE INDEX tmp_outside_after_m5_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_m5 (unique_id_sinp);
CREATE INDEX tmp_outside_after_m5_the_geom_local_idx ON gn_synthese.tmp_outside_after_m5 USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_m5 TO gnreader;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no M1 corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_m1;
CREATE TABLE gn_synthese.tmp_outside_after_m1
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
CREATE INDEX tmp_outside_after_m1_id_synthese_idx ON gn_synthese.tmp_outside_after_m1 (id_synthese);
CREATE INDEX tmp_outside_after_m1_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_m1 (unique_id_sinp);
CREATE INDEX tmp_outside_after_m1_the_geom_local_idx ON gn_synthese.tmp_outside_after_m1 USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_m1 TO gnreader;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no Communes corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_com;
CREATE TABLE gn_synthese.tmp_outside_after_com
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
CREATE INDEX tmp_outside_after_com_id_synthese_idx ON gn_synthese.tmp_outside_after_com (id_synthese);
CREATE INDEX tmp_outside_after_com_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_com (unique_id_sinp);
CREATE INDEX tmp_outside_after_com_the_geom_local_idx ON gn_synthese.tmp_outside_after_com USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_com TO gnreader;
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Compute observations with no Départements corresponding area'
BEGIN;
DROP TABLE IF EXISTS gn_synthese.tmp_outside_after_dep;
CREATE TABLE gn_synthese.tmp_outside_after_dep
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
CREATE INDEX tmp_outside_after_dep_id_synthese_idx ON gn_synthese.tmp_outside_after_dep (id_synthese);
CREATE INDEX tmp_outside_after_dep_unique_id_sinp_idx ON gn_synthese.tmp_outside_after_dep (unique_id_sinp);
CREATE INDEX tmp_outside_after_dep_the_geom_local_idx ON gn_synthese.tmp_outside_after_dep USING gist (the_geom_local);
GRANT SELECT ON TABLE gn_synthese.tmp_outside_after_dep TO gnreader;
COMMIT;
