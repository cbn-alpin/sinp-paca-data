-- Mise à jour TaxRef v15 vers v16 pour le SINP PACA

-- rétablir les contraintes de clés étrangères spécifiques à votre base
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
    ON UPDATE CASCADE ;

-- Enable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

-- Enable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;

-- Mise à jour GeoNature si besoin
UPDATE gn_commons.t_parameters
SET parameter_value = 'Taxref V16.0'
WHERE parameter_name = 'taxref_version' ;
