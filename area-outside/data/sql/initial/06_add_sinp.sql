-- Ajouter à cor_area_synthese l'ensemble des observations en les liant
-- au territoire du SINP même si les observations sont hors de la géométrie
-- correspondante.

BEGIN;


\echo 'Insert all observations in cor_area_synthese link to SINP area'
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    WITH sinp AS (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type('SINP')
        LIMIT 1
    )
    SELECT
        s.id_synthese,
        sinp.id_area
    FROM gn_synthese.synthese AS s, sinp ;
-- ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

COMMIT;
