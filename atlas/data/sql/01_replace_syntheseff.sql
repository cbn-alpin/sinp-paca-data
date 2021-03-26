BEGIN;

CREATE OR REPLACE VIEW synthese.syntheseff AS
WITH obs_data AS (
	SELECT
		s.id_synthese,
		s.cd_nom,
		s.date_min AS dateobs,
		s.observers AS observateurs,
		(s.altitude_min + s.altitude_max) / 2 AS altitude_retenue,
		st_transform(s.the_geom_point, 3857) AS the_geom_point,
		s.count_min AS effectif_total,
		dl.cd_nomenclature::INTEGER AS diffusion_level
	FROM synthese.synthese s
		LEFT JOIN synthese.t_nomenclatures AS dl
			ON (s.id_nomenclature_diffusion_level = dl.id_nomenclature)
		LEFT JOIN synthese.t_nomenclatures AS st
			ON (s.id_nomenclature_observation_status = st.id_nomenclature)
	WHERE ( NOT dl.cd_nomenclature::text = '4'::text OR s.id_nomenclature_diffusion_level IS NULL )
		AND st.cd_nomenclature::text = 'Pr'::text
)
SELECT
	d.id_synthese,
	d.cd_nom,
	d.dateobs,
	d.observateurs,
	d.altitude_retenue,
	d.the_geom_point,
	d.effectif_total,
	c.insee,
	d.diffusion_level
FROM obs_data AS d
	JOIN atlas.l_communes AS c
		ON ( st_intersects(d.the_geom_point, c.the_geom) ) ;

COMMIT;
