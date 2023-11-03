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
        CASE
            WHEN r.champs_addi ->> 'validate_charte' = '["true"]' THEN 'OUI'
            ELSE 'NON'
        END AS charte_valide,
        CASE
            WHEN r.active = TRUE THEN 'OUI'
            ELSE 'NON'
        END AS compte_actif,
        CASE
            WHEN r.pass_plus IS NOT NULL OR r.pass_plus != '' THEN 'OUI'
            ELSE 'NON'
        END AS avec_mot_de_passe,
        r.remarques AS remarques,
        r.champs_addi AS donnees_additionnelles,
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
