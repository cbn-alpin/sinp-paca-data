-- À exécuter sur une base de données comportant toutes les zones géo désirées
-- Il est nécessaire ques les zones géos aient les mêmes id.
BEGIN;

DROP TABLE IF EXISTS gn_synthese.tmp_l_areas_m1 ;

CREATE TABLE gn_synthese.tmp_l_areas_m1 AS
	SELECT DISTINCT la.*
	FROM ref_geo.l_areas la
		JOIN gn_synthese.tmp_outside_m1 tom ON st_intersects(la.geom, tom.the_geom_local)
	WHERE la.id_type = ref_geo.get_id_area_type('M1') ;

CREATE INDEX tmp_l_areas_m1_id_area_idx ON gn_synthese.tmp_l_areas_m1 (id_area);

DROP TABLE IF EXISTS gn_synthese.tmp_li_grids_m1 ;

CREATE TABLE gn_synthese.tmp_li_grids_m1 AS
	SELECT DISTINCT lg2.*
	FROM ref_geo.li_grids lg2
		JOIN gn_synthese.tmp_l_areas_m1 tlam ON tlam.id_area = lg2.id_area ;



DROP TABLE IF EXISTS gn_synthese.tmp_l_areas_m5;

CREATE TABLE gn_synthese.tmp_l_areas_m5 AS
	SELECT DISTINCT la.*
	FROM ref_geo.l_areas la
		JOIN gn_synthese.tmp_outside_m5 tom ON st_intersects(la.geom, tom.the_geom_local)
	WHERE la.id_type = ref_geo.get_id_area_type('M5') ;

CREATE INDEX tmp_l_areas_m5_id_area_idx ON gn_synthese.tmp_l_areas_m5 (id_area);

DROP TABLE IF EXISTS gn_synthese.tmp_li_grids_m5 ;

CREATE TABLE gn_synthese.tmp_li_grids_m5 AS
	SELECT DISTINCT lg2.*
	FROM ref_geo.li_grids lg2
		JOIN gn_synthese.tmp_l_areas_m5 tlam ON tlam.id_area = lg2.id_area ;



DROP TABLE IF EXISTS gn_synthese.tmp_l_areas_m10 ;

CREATE TABLE gn_synthese.tmp_l_areas_m10 AS
	SELECT DISTINCT la.*
	FROM ref_geo.l_areas la
		JOIN gn_synthese.tmp_outside_m10 tom ON st_intersects(la.geom, tom.the_geom_local)
	WHERE la.id_type = ref_geo.get_id_area_type('M10') ;

CREATE INDEX tmp_l_areas_m10_id_area_idx ON gn_synthese.tmp_l_areas_m10 (id_area);

DROP TABLE IF EXISTS gn_synthese.tmp_li_grids_m10 ;

CREATE TABLE gn_synthese.tmp_li_grids_m10 AS
	SELECT DISTINCT lg2.*
	FROM ref_geo.li_grids lg2
		JOIN gn_synthese.tmp_l_areas_m10 tlam ON tlam.id_area = lg2.id_area ;


COMMIT;
