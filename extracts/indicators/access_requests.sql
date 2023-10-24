-- Script to export access requests by year
-- Usage (from local computer): cat ./access_requests.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_access_requests.csv
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
        re.sensitive_access AS acces_donnees_senssible,
        to_char(re.meta_create_date, 'DD/MM/YYYY') AS date_demande,
        to_char(re.processed_date, 'DD/MM/YYYY') AS date_traitement,
        CASE re.processed_state
            WHEN 'refused' THEN 'refusé'
            WHEN 'accepted' THEN 'accepté'
            ELSE ''
        END AS etat,
        re.refusal_reason AS raison_refus,
        to_char(re.end_date, 'DD/MM/YYYY') AS limite_temporelle,
        (
            SELECT string_agg(DISTINCT (area_name), ', ' ORDER BY area_name ASC)
            FROM ref_geo.l_areas
            WHERE id_area::TEXT = ANY (regexp_split_to_array(re.geographic_filter, ','))
        ) AS limites_geographiques,
        (
            SELECT string_agg(
                DISTINCT (
                    CASE
                        WHEN regne = 'Plantae' AND group1_inpn = 'Bryophytes'
                            THEN 'Bryophytes'
                        WHEN regne = 'Plantae' AND group1_inpn = 'Trachéophytes'
                            THEN 'Trachéophytes'
                        WHEN regne = 'Plantae' AND group1_inpn = 'Algues'
                            THEN 'Algues'
                        WHEN regne = 'Fungi'
                            THEN 'Fonge'
                        WHEN regne = 'Animalia' AND phylum IN ('Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes')
                            THEN 'Invertébré'
                        WHEN regne = 'Animalia' AND phylum = 'Chordata'
                            THEN 'Vertébré'
                    END
                ), ', ')
            FROM taxonomie.taxref
            WHERE cd_nom::TEXT = ANY (regexp_split_to_array(re.taxonomic_filter, ','))
        ) AS limites_taxonomiques
    FROM gn_permissions.t_requests AS re
        LEFT JOIN utilisateurs.t_roles AS ro
            ON re.id_role = ro.id_role
        LEFT JOIN utilisateurs.bib_organismes AS o
            ON ro.id_organisme = o.id_organisme
    ORDER BY re.processed_date ASC
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
