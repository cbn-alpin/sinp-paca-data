-- Mise à jour TaxRef v13 vers v14 pour le SINP PACA
BEGIN;


-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;


-- Set cd_nom to NULL for "cd_nom" with NO replacement "cd_nom" in "gn_synthese.synthese"
-- Data provider may wish to update these records.
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (101747) ;

-- Set cd_nom to NULL for removing TaxRef cd_nom
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (211008, 194230, 192435, 199189, 195284);
--Number of row updated by cd_nom : 2, 3, 29, 14, 5,

UPDATE gn_synthese.synthese
SET cd_nom = 771713
WHERE cd_nom = 104306 ;
--Number of row updated by cd_nom : 24

UPDATE gn_synthese.synthese
SET cd_nom = 521658
WHERE cd_nom = 116744 ;
--Number of row updated by cd_nom : 332

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
