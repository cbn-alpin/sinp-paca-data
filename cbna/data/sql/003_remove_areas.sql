-- Remove useless areas from l_areas
BEGIN;
    ALTER TABLE gn_synthese.cor_area_synthese DISABLE TRIGGER ALL;
    ALTER TABLE gn_synthese.cor_area_taxon DISABLE TRIGGER ALL;

    DELETE FROM ref_geo.l_areas AS a USING ref_geo.tmp_region AS c 
    WHERE public.st_intersects(c.geom, a.geom) = false 
        AND insee_reg = '93';

    ALTER TABLE gn_synthese.cor_area_synthese ENABLE TRIGGER ALL;
    ALTER TABLE gn_synthese.cor_area_taxon ENABLE TRIGGER ALL;
COMMIT;

-- Remove useless table	
DROP TABLE IF EXISTS ref_geo.tmp_region;