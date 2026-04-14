--Toutes les groupes taxonomiques faune et flore
--Données sensibles floutées (non précises)
--Données non sensibles non floutées (précises)
--sur la commune de Nice uniquement 
--toute la période temporelle disponible


--select count(*) from (
--données non sensibles
select
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
        t.group2_inpn,
        t.regne,
        n.label_default AS niveau_validation,
        n1.label_default AS sensibilite,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::TIMESTAMP::DATE AS date_debut,
        s.date_max::TIMESTAMP::DATE AS date_fin,
        n2.label_default as nature_objet_geo,
        s."precision" as precision_geographique,
        st_transform(s.the_geom_point,2154) as the_geom_point_2154 ,
        s.the_geom_local as the_geom_local_2154 ,
        s.additional_data

from gn_synthese.synthese s
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
where la.area_name = 'Nice'
and (s.id_nomenclature_sensitivity = 65 or s.id_nomenclature_sensitivity is null)--donnée non sensible

union

--données sensibles
select
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
        t.group2_inpn,
        t.regne,
        n.label_default AS niveau_validation,
        n1.label_default AS sensibilite,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::TIMESTAMP::DATE AS date_debut,
        s.date_max::TIMESTAMP::DATE AS date_fin,
        n2.label_default as nature_objet_geo,
        round((ST_MinimumBoundingRadius(la.geom)).radius) as precision_geographique,--récupération du rayon du cerccle englobant pour la commune
        ST_Centroid(la.geom) as the_geom_point_2154 , --récupération du centroïde de la commune
        la.geom as the_geom_local_2154 ,--récupération de la géométrie de la commune
        s.additional_data

from gn_synthese.synthese s
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
where la.area_name = 'Nice'
and s.id_nomenclature_sensitivity = 66 --donnée sensible
--) as table1 
;
