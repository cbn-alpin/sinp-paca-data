-- Script to export access requests by year
-- Usage (from local computer): cat ./access_requests.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_access_requests.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    WITH limit_taxo AS (
        SELECT
            id_request,
            string_agg(
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
                        WHEN regne = 'Animalia' AND phylum IN (
                            'Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes'
                        )
                            THEN 'Invertébré'
                        WHEN regne = 'Animalia' AND phylum = 'Chordata'
                            THEN 'Vertébré'
                        WHEN regne = 'Plantae' AND group1_inpn = 'Autres'
                            THEN 'Plantae'
                        WHEN regne = 'Animalia' AND phylum is null
                            THEN 'Animalia'
                    END
                ), ', ') AS limites_taxonomiques
        FROM (
                SELECT
                    t1.id_request,
                    t1.cd,t.regne,
                    t.phylum,
                    t.group1_inpn
                FROM (
                        select
                            id_request,
                            unnest(regexp_split_to_array(re.taxonomic_filter, ','))::integer AS cd
                        FROM gn_permissions.t_requests AS re
                        WHERE re.taxonomic_filter IS NOT NULL
                            AND re.taxonomic_filter != ''
                    ) AS t1
                    JOIN taxonomie.taxref AS t
                        ON t.cd_nom = t1.cd
            ) AS t2
        GROUP BY id_request
    ),
    limit_geo AS (
        SELECT
            id_request,
            string_agg(DISTINCT (area_name), ', ' ORDER BY area_name ASC) AS limites_geographiques
        FROM (
                SELECT
                    t1.id_request,
                    t1.id_area,
                    la.area_name
                FROM (
                        SELECT
                            id_request,
                            unnest(regexp_split_to_array(re.geographic_filter, ','))::integer AS id_area
                        FROM gn_permissions.t_requests AS re
                        WHERE re.geographic_filter IS NOT NULL
                            AND re.geographic_filter != ''
                    ) AS t1
                    JOIN ref_geo.l_areas AS la
                        ON la.id_area = t1.id_area
            ) AS t2
        GROUP BY id_request
    )
    SELECT
        ro.nom_role AS nom,
        ro.prenom_role AS prenom,
        o.nom_organisme AS nom_organisme,
        re.additional_data ->> 'userOrganism' AS nom_organisme_demande,
        re.additional_data ->> 'projectType' AS type_etude,
        regexp_replace(re.additional_data ->> 'projectDescription', E'[\\n\\r]+', ' ', 'g' ) AS desc_etude,
        re.additional_data ->> 'kingdom' AS regne_concerne,
        re.sensitive_access AS acces_donnees_sensibles,
        to_char(re.meta_create_date, 'DD/MM/YYYY') AS date_demande,
        to_char(re.processed_date, 'DD/MM/YYYY') AS date_traitement,
        CASE re.processed_state
            WHEN 'refused' THEN 'refusé'
            WHEN 'accepted' THEN 'accepté'
            ELSE ''
        END AS etat,
        regexp_replace(re.refusal_reason, E'[\\n\\r]+', ' ', 'g' ) AS raison_refus,
        to_char(re.end_date, 'DD/MM/YYYY') AS limite_temporelle,
        lg.limites_geographiques,
        lt.limites_taxonomiques
    FROM gn_permissions.t_requests AS re
        LEFT JOIN utilisateurs.t_roles AS ro
            ON re.id_role = ro.id_role
        LEFT JOIN utilisateurs.bib_organismes AS o
            ON ro.id_organisme = o.id_organisme
        LEFT JOIN limit_taxo AS lt
            ON re.id_request = lt.id_request
        LEFT JOIN limit_geo AS lg
            ON re.id_request = lg.id_request
    ORDER BY re.processed_date ASC
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
