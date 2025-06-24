-- Mise à jour TaxRef v17 vers v18 pour le SINP PACA
BEGIN;

-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- -------------------------------------------------------------------------------------------------
-- Manage synthese

UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (138395);

UPDATE gn_synthese.synthese SET cd_nom = 57077 WHERE cd_nom = 658461 ;


-- -------------------------------------------------------------------------------------------------
-- Manage bib_noms

DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (138395)
) ;

DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (138395) ;

UPDATE taxonomie.bib_noms SET cd_nom = 57077 WHERE cd_nom = 658461 ;


-- -------------------------------------------------------------------------------------------------
-- Manage t_sensitivity_rules

UPDATE gn_sensitivity.t_sensitivity_rules SET cd_nom = 138121 WHERE cd_nom = 718726 ;

UPDATE gn_sensitivity.t_sensitivity_rules SET cd_nom = 124412 WHERE cd_nom = 124413 ;


-- Commit if all good
COMMIT;