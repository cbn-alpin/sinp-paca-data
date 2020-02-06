ALTER TABLE cbna_flore_global.releve_flore_global SET SCHEMA imports_cbna;
ALTER TABLE imports_cbna.releve_flore_global RENAME TO source_v20200124;
DROP SCHEMA cbna_flore_global;

CREATE TABLE imports_cbna.import_v20200124 AS (SELECT * FROM imports_cbna.source_v20200124);

-- Suppression des données hors région PACA
DELETE FROM imports_cbna.import_v20200124 AS i USING ref_geo.tmp_region AS r
    WHERE public.st_intersects(r.geom, i.the_geom_point) = false 
    AND insee_reg = '93';