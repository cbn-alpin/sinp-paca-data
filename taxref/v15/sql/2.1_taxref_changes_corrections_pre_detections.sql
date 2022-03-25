-- Mise à jour TaxRef v14 vers v15 pour le SINP PACA
BEGIN;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- Set cd_nom to NULL for removing TaxRef cd_nom
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (717262, 810958, 243151, 610817);
--Number of row updated by cd_nom : 1, 6, 2, 1

-- Deleting row from "cor_nom_liste"
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (102214, 243151, 610817, 717262, 810958)
) ;

-- Deleting row with problems solved in "taxonomie.bib_noms"
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (102214, 243151, 610817, 717262, 810958) ;

-- Commit if all good
COMMIT;
