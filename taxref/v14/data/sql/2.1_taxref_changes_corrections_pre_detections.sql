-- Mise à jour TaxRef v13 vers v14 pour le SINP PACA
BEGIN;


-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;


-- Deleting row with "cd_nom" with NO replacement "cd_nom" in "gn_synthese.synthese"
DELETE FROM gn_synthese.synthese
WHERE cd_nom IN (101747) ;


-- Deleting row from "cor_nom_liste"
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (101747)
) ;

-- Deleting row with problems solved in "taxonomie.bib_noms"
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (101747) ;

-- Commit if all good
COMMIT;
