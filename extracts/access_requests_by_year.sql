-- Script to export access requests by year
-- Usage (from local computer): cat ./access_requests_by_year.sql | sed 's/${year}/<my-year>/g'| ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_access_requests.csv
-- - <my-year> : replace with the desired year.
-- - <db-user-pwd> : replace with the database user password.
\timing off 
COPY (
        SELECT 
            ro.nom_role AS nom, 
            ro.prenom_role AS prenom,
            o.nom_organisme AS nom_organisme,
            re.additional_data ->> 'userOrganism' AS nom_organisme_demande, 
            re.additional_data ->> 'projectType' AS type_etude,
            re.additional_data ->> 'projectDescription' AS desc_etude,
            re.additional_data ->> 'kingdom' AS regne_concerne,
            to_char(re.meta_create_date, 'DD/MM/YYYY') AS date_demande
        FROM gn_permissions.t_requests AS re
            LEFT JOIN utilisateurs.t_roles AS ro
                ON re.id_role = ro.id_role 
            LEFT JOIN utilisateurs.bib_organismes AS o 
                ON ro.id_organisme = o.id_organisme 
        WHERE re.meta_create_date > '${year}-01-01 00:00:00'
            AND re.meta_create_date < '${year}-12-31 23:59:59.999999'
            AND re.processed_state = 'accepted'
        ORDER BY re.processed_date ASC 
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
