ALTER TABLE cbna_flore_global.releve_flore_global SET SCHEMA imports_cbna;
ALTER TABLE imports_cbna.releve_flore_global RENAME TO flore_v20190124;
DROP SCHEMA cbna_flore_global;

-- TODO : sélectionner seulement les données régions PACA
-- DELETE FROM ref_geo.l_areas AS a USING ref_geo.tmp_region AS c 
-- WHERE public.st_intersects(c.geom, a.geom) = false 
--    AND insee_reg = '93';