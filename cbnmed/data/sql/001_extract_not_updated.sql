-- Script to extract not existing unique ID in synthese for observation to update
-- Usage (from local computer): cat ./001_* | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_uuid_not_existing.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    SELECT cs.unique_id_sinp
    FROM gn_imports.cbnmed_20220311_synthese AS cs
	LEFT JOIN gn_synthese.synthese AS s
		ON s.unique_id_sinp = cs.unique_id_sinp
    WHERE meta_last_action = 'U'
	    AND s.unique_id_sinp IS NULL
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
