-- Mise à jour TaxRef v13 vers v14 pour le SINP PACA

-- rétablir les contraintes de clés étrangères spécifiques à votre base
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
    ON UPDATE CASCADE ;

-- Mise à jour GeoNature si besoin
UPDATE gn_commons.t_parameters
SET parameter_value = 'Taxref V14.0'
WHERE parameter_name = 'taxref_version' ;
