-- Mise à jour TaxRef v17 vers v18 pour le SINP PACA

-- Enable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

-- Enable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;

-- Mise à jour GeoNature si besoin
UPDATE gn_commons.t_parameters
SET parameter_value = 'Taxref V18.0'
WHERE parameter_name = 'taxref_version' ;