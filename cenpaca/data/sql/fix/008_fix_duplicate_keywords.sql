\ echo 'Fix duplicate keyword faune in datasets table.'
\ echo 'Rights: db-owner'
\ echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/cenpaca/data/sql/fix/008_*
BEGIN;

\ echo '----------------------------------------------------------------------------'
\ echo 'Updating datasets keywords...'

UPDATE gn_meta.t_datasets AS d
SET keywords = unduplicate.keywords
FROM (
	SELECT
	    td.id_dataset,
	    td.keywords AS origin,
	    (
	        SELECT array_to_string(
	            ARRAY(
	                SELECT DISTINCT trim(x)
	                FROM unnest(string_to_array(td.keywords, ',')) AS x
	            ),
	            ', '
	        )
	    ) AS keywords
	FROM gn_meta.t_datasets AS td
	WHERE td.keywords ILIKE '%faune%'
) AS unduplicate
WHERE d.id_dataset = unduplicate.id_dataset ;

\ echo '----------------------------------------------------------------------------'
\ echo 'COMMIT if all is ok:'
COMMIT;
