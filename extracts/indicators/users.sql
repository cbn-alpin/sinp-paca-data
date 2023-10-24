-- Script to export users by year
-- Usage (from local computer): cat ./users.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_users.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    SELECT
        r.uuid_role AS uuid,
        r.prenom_role AS prenom,
        r.nom_role AS nom,
        r.email AS email,
        r.remarques AS remarques,
        r.date_insert AS date_inscription,
        r.date_update AS date_mise_a_jour,
        o.nom_organisme AS organisme_nom,
        o.uuid_organisme AS organisme_uuid
    FROM utilisateurs.t_roles AS r
        LEFT JOIN utilisateurs.bib_organismes AS o
            ON r.id_organisme = o.id_organisme
    WHERE groupe = FALSE
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
