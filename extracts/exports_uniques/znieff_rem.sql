--Emprise : toute la région PACA
--Période : toute la période disponible dans Silene
--Listes d'espèces : cf. fichier joints (liste des espèces déterminantes ZNIEFF et liste des espèces remarquables).
--Précision de localisation : exclure les données communales et supérieures (mailles 10x10km) sauf pour les communes suivantes pour lesquelles ne faire aucune sélection de localisation : 
--Saint-Antonin, Les Baux-de-Provence, La Brigue, Lagarde-d'Apt, Saint-Antonin-sur-Bayon, Plan-d'Aups-Ste-Baume, Riboux, Auvare, La Croix-sur-Roudoule, Arvieux, Névache, La Chapelle-en-Valgaudemar.
--Données sensibles floutées
--Format d’export souhaités : si c’est possible de faire 2 fichiers de sortie : un concernant les espèces déterminantes et un pour les espèces remarquables. Avec bien présence du champ 
--département dans chacun des fichiers pour bien faire le tri par ZNIEFF en suite.


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
        t.nom_vern,
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
        s.additional_data ->> 'precisionLabel' as precisionLabel,
        la.area_code,
        la.area_name,
        left(la.area_code,2) as dep,
        s.additional_data


from gn_synthese.synthese s
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join ref_geo.tmp_jmg_liste_sp_rem l on t.cd_ref = l.cd_ref 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature

where la.id_type = 25 and la.area_code in ('06115','13011','06162','84060','13090','83093','83105','06008','06051','05007','05093','05064')
and (s.id_nomenclature_sensitivity=65 or s.id_nomenclature_sensitivity is null) 

union

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
        t.nom_vern,
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
        s.additional_data ->> 'precisionLabel' as precisionLabel,
        la.area_code,
        la.area_name,
        left(la.area_code,2) as dep,
        s.additional_data


from gn_synthese.synthese s
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join ref_geo.tmp_jmg_liste_sp_rem l on t.cd_ref = l.cd_ref 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature

where la.id_type = 25 and not(la.area_code in ('06115','13011','06162','84060','13090','83093','83105','06008','06051','05007','05093','05064'))
and (s.id_nomenclature_sensitivity=65 or s.id_nomenclature_sensitivity is null)
and not(s.additional_data @> '{"precisionLabel": "commune"}')

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
        t.nom_vern,
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
        round((ST_MinimumBoundingRadius(la.geom)).radius) as precision_geographique,
        ST_Centroid(la.geom) as the_geom_point_2154 ,
        la.geom as the_geom_local_2154 ,
        'commune' as precisionLabel,
        la.area_code,
        la.area_name,
        left(la.area_code,2) as dep,
        s.additional_data


from gn_synthese.synthese s
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join ref_geo.tmp_jmg_liste_sp_rem l on t.cd_ref = l.cd_ref 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature

where la.id_type = 25 and la.area_code in ('06115','13011','06162','84060','13090','83093','83105','06008','06051','05007','05093','05064')
and s.id_nomenclature_sensitivity=66 


union

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
        t.nom_vern,
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
        round((ST_MinimumBoundingRadius(la.geom)).radius) as precision_geographique,
        ST_Centroid(la.geom) as the_geom_point_2154 ,
        la.geom as the_geom_local_2154 ,
        'commune' as precisionLabel,
        la.area_code,
        la.area_name,
        left(la.area_code,2) as dep,
        s.additional_data


from gn_synthese.synthese s
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join ref_geo.tmp_jmg_liste_sp_rem l on t.cd_ref = l.cd_ref 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature;

where la.id_type = 25 and not(la.area_code in ('06115','13011','06162','84060','13090','83093','83105','06008','06051','05007','05093','05064'))
and not(s.additional_data @> '{"precisionLabel": "commune"}')
and s.id_nomenclature_sensitivity=66 
