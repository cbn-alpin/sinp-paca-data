-- Add SINP area
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Insert SINP area type'
INSERT INTO ref_geo.bib_areas_types (
    type_name,
    type_code,
    type_desc,
    ref_name,
    ref_version
)
    SELECT
        'Territoire SINP',
        'SINP',
        'Zone concernée par les données du SINP régional.',
        'IGN admin_express',
        2017
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = 'SINP'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert SINP area'
INSERT INTO ref_geo.l_areas (
    id_type,
    area_name,
    area_code,
    geom,
    "enable"
)
	SELECT
        ref_geo.get_id_area_type('SINP'),
        nom_reg,
        insee_reg,
        geom,
        TRUE
	FROM :areasTmpTable
	WHERE insee_reg = :'sinpRegId'
        AND NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = :'sinpRegId'
                AND la.id_type = ref_geo.get_id_area_type('SINP')
        ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
