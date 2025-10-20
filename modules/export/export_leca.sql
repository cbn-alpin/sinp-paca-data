--. périmètre taxonomique : données flore uniquement, sensibles et non sensibles ;
--. échelle : maille 5x5km
--. périmètre géographique : 04 / 05 /06
--. période : 1990-2025

-- gn_exports.leca_flore_m5

CREATE MATERIALIZED VIEW gn_exports.leca_flore_m5
TABLESPACE pg_default
AS 

with 
liste_obs as (
select s.id_synthese,st_transform(s.the_geom_point , 2154) as geom_pt_2154
from gn_synthese.synthese s 
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 

where t.regne = 'Plantae'
and la.id_type = 26 and la.area_code in ('04','05','06')
and s.date_min >= '1990-01-01'
),

liste_obs_maille as (
select lo.*,la. area_code
from liste_obs lo
join ref_geo.l_areas la on st_within(lo.geom_pt_2154,la.geom)
where la.id_type = 28
)


select s.*, lom.area_code 
from gn_synthese.synthese s 
join liste_obs_maille lom on s.id_synthese = lom.id_synthese
--join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
--join ref_geo.l_areas la on cas.id_area = la.id_area
--where la.id_type = 28
