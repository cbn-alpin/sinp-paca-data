-- Clean data
DELETE FROM ref_geo.l_areas WHERE id_type = ref_geo.get_id_area_type('SINP');
DELETE FROM ref_geo.bib_areas_types WHERE type_code = 'SINP';

-- Insert SINP area
INSERT INTO ref_geo.bib_areas_types (type_name, type_code, type_desc, ref_name, ref_version) 
VALUES ('Territoire SINP', 'SINP', 'Région PACA', 'IGN admin_express', 2017);

INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, "enable")
	SELECT ref_geo.get_id_area_type('SINP'), nom_reg, insee_reg, geom, TRUE 
	FROM ref_geo.tmp_region 
	WHERE insee_reg = '93';

-- Remove useless table	
DROP TABLE IF EXISTS ref_geo.tmp_region;