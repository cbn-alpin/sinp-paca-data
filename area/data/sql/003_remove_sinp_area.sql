-- Remove previous added SINP area and linked data
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Clean data from "cor_area_synthese"'
DELETE FROM gn_synthese.cor_area_synthese WHERE id_area IN (
	SELECT id_area FROM ref_geo.l_areas WHERE id_type IN (
		SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SINP'
	)
);


\echo '----------------------------------------------------------------------------'
\echo 'Clean data from "cor_area_taxon"'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' Clean table cor_area_taxon' ;
            DELETE FROM gn_synthese.cor_area_taxon WHERE id_area IN (
	            SELECT id_area FROM ref_geo.l_areas WHERE id_type IN (
		            SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SINP'
	            )
            );
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Remove SINP area from "l_area"'
DELETE FROM ref_geo.l_areas WHERE id_type IN (
	SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SINP'
);


\echo '----------------------------------------------------------------------------'
\echo 'Remove SINP area type from "bib_areas_types"'
DELETE FROM ref_geo.bib_areas_types WHERE type_code = 'SINP';


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
