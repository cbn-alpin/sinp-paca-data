--Territoire : tout PACA
--Période : du 01/01/2005 au 31/12/2024
--Taxons concernés : familles suivantes : Papilionidae, Hesperiidae, Pieridae, Nymphalidae, Lycaenidae, Riodinidae, Zygaenidae.


-- gn_exports.opie_papillons

CREATE MATERIALIZED VIEW gn_exports.opie_papillons
TABLESPACE pg_default
as
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
        n.label_default AS niveau_validation,
        n1.label_default AS sensibilite,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::TIMESTAMP::DATE AS date_debut,
        s.date_max::TIMESTAMP::DATE AS date_fin,
        n2.label_default as nature_objet_geo,
        s."precision" as precision_geographique,
        s.the_geom_point ,
        s.the_geom_local ,
        s.additional_data
from gn_synthese.synthese s 
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese
left JOIN gn_meta.t_datasets as j ON j.id_dataset = s.id_dataset
left JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
left JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_sensitivity = n1.id_nomenclature 
left JOIN ref_nomenclatures.t_nomenclatures AS n2 ON s.id_nomenclature_geo_object_nature = n2.id_nomenclature
where t.famille in ('Papilionidae', 'Hesperiidae', 'Pieridae', 'Nymphalidae', 'Lycaenidae', 'Riodinidae', 'Zygaenidae')
and s.date_min >= '2005-01-01'
and s.date_max < '2025-01-01';
