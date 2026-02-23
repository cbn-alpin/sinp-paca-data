--export d'après la liste de CD_nom fournits : ref_geo.tmp_jmg_dreal_liste_taxons_cdnoms
--date >= '2000-01-01'
--donnnées localisées précisément


with 

taxons as (
select distinct t.cd_ref
from ref_geo.tmp_jmg_dreal_liste_taxons_cdnoms l
join taxonomie.taxref t on l.cd_nom = t.cd_nom
)

select 
s.id_synthese,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    sd.dataset_name AS jdd_nom,
    sd.unique_dataset_id AS jdd_uuid,
    sd.organisms AS fournisseur,
    s.observers AS observateurs,
    t.cd_ref,
    t.nom_valide,
    t.nom_vern AS nom_vernaculaire,
    t.classe,
    t.famille,
    t.ordre,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    st_astext(s.the_geom_local) AS geom__2154,
    st_x(st_transform(st_centroid(s.the_geom_point), 2154)) AS x_centroid_2154,
    st_y(st_transform(st_centroid(s.the_geom_point), 2154)) AS y_centroid_2154,
    s."precision" AS precision_geographique,
    s.additional_data ->> 'precisionLabel'::text AS type_precision,
    sa.communes,
    s.altitude_min AS alti_min,
    n3.label_default AS technique_observation,
    n10.label_default AS stade_vie,
    n5.label_default AS statut_biologique,
    n11.label_default AS sexe,
    n20.label_default AS comportement,
    n17.label_default AS type_source,
        CASE
            WHEN ns.cd_nomenclature::text = '0'::text THEN 'donnée non sensible'::text
            WHEN s.id_nomenclature_sensitivity IS NULL THEN ''::text
            ELSE 'donnée sensible'::text
        END AS sensibilite,
        CASE
            WHEN (s.additional_data ->> 'confidential'::text) = 'true'::text THEN 'donnée confidentielle'::text
            ELSE 'donnée non confidentielle'::text
        END AS confidentialite,
    COALESCE(nb.cd_nomenclature, 'NON'::character varying) AS floutage--,
    --sd.id_dataset AS jdd_id,
    --s.id_digitiser,
    --st_asgeojson(s.the_geom_local) AS geojson_local,
    --s.id_nomenclature_sensitivity,
    --s.id_nomenclature_diffusion_level
    --ns.label_default as lb_sensibilite,
    --nb.label_default as lb_floutage
    
from gn_synthese.synthese s 
join taxonomie.taxref t on s.cd_nom = t.cd_nom
join taxons tx on t.cd_ref = tx.cd_ref
     LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'COM'::text
          WHERE cas.id_synthese = s.id_synthese
          GROUP BY cas.id_synthese) sa ON true
     LEFT JOIN LATERAL ( SELECT td.id_dataset,
            td.dataset_name,
            td.unique_dataset_id,
            string_agg(DISTINCT bo.nom_organisme::text, ', '::text) AS organisms
           FROM gn_meta.t_datasets td
             LEFT JOIN gn_meta.cor_dataset_actor cad ON cad.id_dataset = td.id_dataset AND (cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '5'::character varying) OR cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '6'::character varying))
             LEFT JOIN utilisateurs.bib_organismes bo ON bo.id_organisme = cad.id_organism
          WHERE td.id_dataset = s.id_dataset
          GROUP BY td.id_dataset) sd ON true
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures ns ON s.id_nomenclature_sensitivity = ns.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures nb ON s.id_nomenclature_blurring = nb.id_nomenclature
where s.date_min >= '2000-01-01' and s.additional_data@>'{"precisionLabel": "précis"}' ;
