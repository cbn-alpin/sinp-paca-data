\echo 'Fix encoding value error in additional_data field of synthese table.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/cenpaca/data/sql/fix/006_*

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Update additional_data to fix encoding'
UPDATE gn_synthese.synthese
SET additional_data = REPLACE(additional_data::text, 'prÃ©cis', 'précis')::jsonb
WHERE (additional_data -> 'precisionLabel') IS NOT NULL
	AND additional_data ->> 'precisionLabel' = 'prÃ©cis';

\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean table gn_synthese.synthese '
VACUUM VERBOSE ANALYSE gn_synthese.synthese ;
