-- Mise à jour TaxRef v16 vers v17 pour le SINP PACA
BEGIN;

-- Database change in TaxHub v1.14.0
DROP TABLE IF EXISTS taxonomie.t_meta_taxref ;

CREATE TABLE taxonomie.t_meta_taxref (
    referencial_name varchar NOT NULL,
    "version" int4 NOT NULL,
    update_date timestamp DEFAULT now() NULL,
    CONSTRAINT t_meta_taxref_pkey PRIMARY KEY (referencial_name, version)
);

WITH meta_taxref AS (
    SELECT 1019039 as max_cd_nom, 16 AS taxref_version
    UNION
    SELECT 1002708  as max_cd_nom, 15 AS taxref_version
    UNION
    SELECT 972486  as max_cd_nom, 14 AS taxref_version
    UNION
    SELECT 935095  as max_cd_nom, 13 AS taxref_version
    UNION
    SELECT 887126  as max_cd_nom, 11 AS taxref_version
)
INSERT INTO taxonomie.t_meta_taxref (referencial_name, version)
    SELECT 'taxref', m.taxref_version
    FROM taxonomie.taxref AS t
        JOIN meta_taxref AS m
            ON t.cd_nom = m.max_cd_nom
    ORDER BY t.cd_nom DESC
    LIMIT 1;


-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- Set cd_nom to NULL for removing TaxRef cd_nom
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (116017, 240582);

-- Deleting row from "cor_nom_liste"
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (116017, 240582, 161493)
) ;

-- Deleting row with problems solved in "taxonomie.bib_noms"
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (116017, 240582, 161493) ;

-- Commit if all good
COMMIT;
