-- Required rights: DB OWNER
-- Replace synthese profile view to avoid sensitive and private observations
-- Transfert this script on server this way:
-- rsync -av ./05_* geonat@db-paca-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db -f ~/data/db-geonature/data/sql/05_*
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Recreate VIEW gn_profiles.v_synthese_for_profiles'

--
DROP VIEW gn_synthese.v_synthese_for_export ;

CREATE OR REPLACE VIEW gn_profiles.v_synthese_for_profiles AS
    WITH excluded_live_stage AS (
        SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0') AS id_n_excluded
        UNION
        SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1') AS id_n_excluded
    )
    SELECT s.id_synthese,
        s.cd_nom,
        s.nom_cite,
        t.cd_ref,
        t.nom_valide,
        t.id_rang,
        s.date_min,
        s.date_max,
        s.the_geom_local,
        s.the_geom_4326,
        s.altitude_min,
        s.altitude_max,
        CASE
            WHEN (s.id_nomenclature_life_stage IN ( SELECT excluded_live_stage.id_n_excluded
                FROM excluded_live_stage)) THEN NULL::integer
            ELSE s.id_nomenclature_life_stage
        END AS id_nomenclature_life_stage,
        s.id_nomenclature_valid_status,
        p.spatial_precision,
        p.temporal_precision_days,
        p.active_life_stage,
        p.distance
    FROM gn_synthese.synthese s
        LEFT JOIN taxonomie.taxref t
            ON s.cd_nom = t.cd_nom
        LEFT JOIN ref_nomenclatures.t_nomenclatures AS sens
		    ON (s.id_nomenclature_sensitivity = sens.id_nomenclature)
	    LEFT JOIN ref_nomenclatures.t_nomenclatures AS dl
		    ON (s.id_nomenclature_diffusion_level = dl.id_nomenclature)
        CROSS JOIN LATERAL gn_profiles.get_parameters(s.cd_nom) AS p
            (cd_ref, spatial_precision, temporal_precision_days, active_life_stage, distance)
    WHERE ( dl.cd_nomenclature = '5' OR s.id_nomenclature_diffusion_level IS NULL )
	    AND ( sens.cd_nomenclature = '0' OR s.id_nomenclature_sensitivity IS NULL )
        AND p.spatial_precision IS NOT NULL
        AND st_maxdistance(st_centroid(s.the_geom_local), s.the_geom_local) < p.spatial_precision::double precision
        AND s.altitude_max IS NOT NULL
        AND s.altitude_min IS NOT NULL
        AND (s.id_nomenclature_valid_status IN (
            SELECT regexp_split_to_table(t_parameters.value, ',')::integer AS regexp_split_to_table
            FROM gn_profiles.t_parameters
            WHERE t_parameters.name::text = 'id_valid_status_for_profiles')
        )
        AND (t.id_rang::text IN (
            SELECT regexp_split_to_table(t_parameters.value, ',') AS regexp_split_to_table
            FROM gn_profiles.t_parameters
            WHERE t_parameters.name::text = 'id_rang_for_profiles')
        ) ;

\echo '----------------------------------------------------------------------------'
COMMIT;
