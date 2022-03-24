-- Mise à jour TaxRef v12 vers v13 pour le SINP PACA
BEGIN;


-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;


-- Deleting row with "cd_nom" with NO replacement "cd_nom" in "gn_synthese.synthese"
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (342470, 194230, 211008) ;


-- Deleting row from "cor_nom_liste"
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (342470)
) ;

-- Deleting row with problems solved in "taxonomie.bib_noms"
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (342470) ;

-- Commit if all good
COMMIT;
