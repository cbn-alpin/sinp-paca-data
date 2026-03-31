--Serait-il possible de préparer un export (à me transmettre via un lien de téléchargement ou par email, mais pas par le module Export) avec les éléments suivants stp :
--Liste des taxons concernés en pj
--Période : les 20 dernières années, donc toutes les données à partir de 2006
--Territoire : toute la région PACA
--Précision de localisation : toutes les précisions géographiques disponibles, pas de filtre
--Format d’export : csv (ou excel selon ce qui t’arranges). Est-il possible d’avoir un export en Json aussi ? Ils voudraient faire un test pour mettre à jour en direct des cartes de répartition avec cet export. Si ce n’est pas possible, pas de soucis.


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
        s.additional_data


from gn_synthese.synthese s
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join gn_synthese.tmp_jmg_liste_eaee_arbe_2026 l on t.cd_ref = l.cd_ref 
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
where date_part('year', s.date_min) >= '2006'
;
