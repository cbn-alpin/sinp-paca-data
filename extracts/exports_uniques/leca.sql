--. périmètre taxonomique : données flore uniquement, sensibles et non sensibles ;
--. échelle : maille 5x5km
--. périmètre géographique : 04 / 05 /06
--. période : 1990-2025

-- gn_exports.leca_flore_m5
CREATE MATERIALIZED VIEW gn_exports.leca_flore_m5_v2
TABLESPACE pg_default
AS 

SELECT 
    --s.*, 
    --maille.area_code
    	s.unique_id_sinp AS uuid_perm_sinp,
        s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
        c.unique_acquisition_framework_id AS ca_uuid,
        c.acquisition_framework_name AS ca_nom,
        j.unique_dataset_id AS jdd_uuid,
        j.dataset_name AS jdd_nom,
        s."validator" AS validateur,
        s.observers AS observateurs,
        t.cd_ref,
        t.nom_valide,
        t.famille,
        n.label_default AS niveau_validation,
        n1.label_default AS sensibilite,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::TIMESTAMP::DATE AS date_debut,
        s.date_max::TIMESTAMP::DATE AS date_fin,
        n2.label_default as nature_objet_geo,
        s.additional_data , 
        maille.area_code as code_maille
FROM gn_synthese.synthese s
JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
-- Jointure pour filtrer par département (existante et rapide via index)
JOIN gn_synthese.cor_area_synthese cas ON s.id_synthese = cas.id_synthese 
JOIN ref_geo.l_areas la_dep ON cas.id_area = la_dep.id_area
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
-- Jointure spatiale LATERAL optimisée
-- On cherche la maille UNIQUEMENT pour les lignes qui passent les filtres précédents
LEFT JOIN LATERAL (
    SELECT la.area_code
    FROM ref_geo.l_areas la
    WHERE la.id_type = 28
    -- ST_Intersects est souvent utilisé comme filtre primaire rapide avant ST_Within
    AND ST_Intersects(la.geom, ST_Transform(s.the_geom_point, 2154))
    --AND ST_Within(ST_Transform(s.the_geom_point, 2154), la.geom)
    LIMIT 1 -- On s'arrête dès qu'on trouve la maille (évite les doublons)
) maille ON true

WHERE t.regne = 'Plantae'
  AND s.date_min >= '1990-01-01'
  AND la_dep.id_type = 26 
  AND la_dep.area_code IN ('04', '05', '06')
  -- Filtre pour ne garder que ceux qui ont trouvé une maille (équivalent à votre inner join)
  AND maille.area_code IS NOT NULL;
