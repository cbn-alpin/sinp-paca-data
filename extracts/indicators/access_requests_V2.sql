with 
limit_taxo as (select 
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
                        WHEN regne = 'Animalia' AND phylum IN ('Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes')
                            THEN 'Invertébré'
                        WHEN regne = 'Animalia' AND phylum = 'Chordata'
                            THEN 'Vertébré'
                        WHEN regne = 'Plantae' AND group1_inpn = 'Autres'
                            THEN 'Plantae' 
                        WHEN regne = 'Animalia' AND phylum is null
                            THEN 'Animalia'                         
                    END
                ), ', ') as limites_taxonomiques from (
            select t1.id_request,t1.cd,t.regne, t.phylum,t.group1_inpn from (
            select id_request, unnest(regexp_split_to_array(re.taxonomic_filter, ','))::integer as cd
            from gn_permissions.t_requests re
            where re.taxonomic_filter is not null and re.taxonomic_filter != ''
            ) as t1
            join taxonomie.taxref t on t.cd_nom = t1.cd
            ) as t2
            group by id_request
            ),
            
 limit_geo as (
             select 
            id_request,
            string_agg(DISTINCT (area_name), ', ' ORDER BY area_name ASC) as limites_geographiques from (
            select t1.id_request,t1.id_area,la.area_name from (
            select id_request, unnest(regexp_split_to_array(re.geographic_filter, ','))::integer as id_area
            from gn_permissions.t_requests re
            where re.geographic_filter is not null and re.geographic_filter != ''
            ) as t1
            join ref_geo.l_areas la on la.id_area = t1.id_area
            ) as t2
            group by id_request
            )
    select 
        ro.nom_role AS nom,
        ro.prenom_role AS prenom,
        o.nom_organisme AS nom_organisme,
        re.additional_data ->> 'userOrganism' AS nom_organisme_demande,
        re.additional_data ->> 'projectType' AS type_etude,
        re.additional_data ->> 'projectDescription' AS desc_etude,
        re.additional_data ->> 'kingdom' AS regne_concerne,
        re.sensitive_access AS acces_donnees_sensibles,
        to_char(re.meta_create_date, 'DD/MM/YYYY') AS date_demande,
        to_char(re.processed_date, 'DD/MM/YYYY') AS date_traitement,
        CASE re.processed_state
            WHEN 'refused' THEN 'refusé'
            WHEN 'accepted' THEN 'accepté'
            ELSE ''
        END AS etat ,
        re.refusal_reason AS raison_refus,
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
