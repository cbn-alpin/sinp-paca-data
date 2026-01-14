--Bassin versant de l’Argens (couche kml en pj)
--Toutes les données flore (hors données sensibles)
--Toutes les données faune de ces groupes (groupe 2 INPN) : insectes, oiseaux, amphibiens, reptiles,mammifères
--Aucune limite de temps


with 
donnees_bv as (
select *
from gn_synthese.synthese s 
join ref_geo.tmp_jmg_bv_argens bv on st_intersects(bv.bv_geom ,s.the_geom_local )
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
)

select
		s.unique_id_sinp AS uuid_perm_sinp,
        s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
        c.unique_acquisition_framework_id AS ca_uuid,
        c.acquisition_framework_name AS ca_nom,
        j.unique_dataset_id AS jdd_uuid,
        j.dataset_name AS jdd_nom,
        s."validator" AS validateur,
        s.observers AS observateurs,
        s.cd_ref,
        s.nom_valide,
        s.famille,
        s.group2_inpn,
        s.regne,
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

from (
select *
from donnees_bv
where group2_inpn in ('Insectes','Oiseaux','Amphibiens','Mammifères','Reptiles')

union

select *
from donnees_bv
where regne = 'Plantae' and (id_nomenclature_sensitivity = 65 or id_nomenclature_sensitivity is null)
) as s
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
;




--select distinct s.id_nomenclature_sensitivity , n.label_default 
--from gn_synthese.synthese s
--join ref_nomenclatures.t_nomenclatures n on s.id_nomenclature_sensitivity = n.id_nomenclature ;
