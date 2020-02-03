DO $$
DECLARE
    step INTEGER := 499999 ;
    stopAt INTEGER := 7500000 ;
    offsetCnt INTEGER := 0 ;
BEGIN
    WHILE offsetCnt < stopAt LOOP
        INSERT INTO gn_synthese.synthese( 
            id_synthese, 
            id_dataset, 
            id_source, 
            -- id_module, 
            -- id_digitiser, 
            entity_source_pk_value, 
            unique_id_sinp, 
            unique_id_sinp_grp, 
            nom_cite, 
            cd_nom, 
            meta_v_taxref, 
            date_min, 
            date_max, 
            observers, 
            the_geom_local, 
            the_geom_4326, 
            the_geom_point,
            altitude_min, 
            altitude_max, 
            count_min, 
            count_max, 
            non_digital_proof, 
            -- digital_proof, 
            -- sample_number_proof, 
            -- determiner, 
            comment_description, 
            comment_context, 
            -- validator, 
            -- validation_comment, 
            -- meta_validation_date, 
            id_nomenclature_observation_status, 
            id_nomenclature_info_geo_type, 
            id_nomenclature_geo_object_nature, 
            id_nomenclature_obs_meth, 
            id_nomenclature_bio_status,
            id_nomenclature_obs_technique, 
            id_nomenclature_naturalness, 
            id_nomenclature_life_stage, 
            id_nomenclature_exist_proof, 
            id_nomenclature_determination_method, 
            id_nomenclature_bio_condition, 
            id_nomenclature_sex,
            id_nomenclature_blurring, 
            id_nomenclature_diffusion_level, 
            id_nomenclature_source_status, 
            id_nomenclature_sensitivity, 
            id_nomenclature_valid_status,
            id_nomenclature_grp_typ, 
            id_nomenclature_type_count, 
            id_nomenclature_obj_count, 
            -- last_action, 
            meta_update_date, 
            meta_create_date
        ) 
            SELECT 
                nextval('gn_synthese.synthese_id_synthese_seq'::regclass)::INT AS id_synthese, 
                gn_meta.get_id_dataset('b3988db2-2c94-4e1f-86f3-3a7184fc5f71') AS id_dataset, 
                gn_synthese.get_id_source('CBNA - Flore globale') AS id_source, 
                -- a.UNDEFINED::INT AS id_module, 
                -- a.UNDEFINED::INT AS id_digitiser, 
                a.idreleve_flore_global::VARCHAR AS entity_source_pk_value, 
                a.uuidreleve_flore_str::UUID AS unique_id_sinp, 
                a.uuidreleve_flore_sta::UUID AS unique_id_sinp_grp, 
                a.str_especes::VARCHAR AS nom_cite, 
                a.taxref_cd_nom::INT AS cd_nom,     
                11::VARCHAR AS meta_v_taxref, 
                a.rel_dateobserv::TIMESTAMP AS date_min, 
                a.rel_dateobserv::TIMESTAMP AS date_max, 
                CONCAT_WS(
                    ', ', 
                    CASE WHEN (NULLIF(libobs1, '') IS NOT NULL) THEN 
                        CASE WHEN (NULLIF(instit_nom1, '') IS NOT NULL) THEN 
                            CONCAT(libobs1, ' (', replace(instit_nom1, ' (Rattachement automatique)', ''), ')')
                        ELSE 
                            libobs1
                        END
                    END,
                    CASE WHEN (NULLIF(libobs2, '') IS NOT NULL) THEN 
                        CASE WHEN (NULLIF(instit_nom2, '') IS NOT NULL) THEN 
                            CONCAT(libobs2, ' (', replace(instit_nom2, ' (Rattachement automatique)', ''), ')')
                        ELSE 
                            libobs2
                        END
                    END,
                    CASE WHEN (NULLIF(libobs3, '') IS NOT NULL) THEN 
                        CASE WHEN (NULLIF(instit_nom3, '') IS NOT NULL) THEN 
                            CONCAT(libobs3, ' (', replace(instit_nom3, ' (Rattachement automatique)', ''), ')')
                        ELSE 
                            libobs3
                        END
                    END,
                    CASE WHEN (NULLIF(libobs4, '') IS NOT NULL) THEN 
                        CASE WHEN (NULLIF(instit_nom4, '') IS NOT NULL) THEN 
                            CONCAT(libobs4, ' (', replace(instit_nom4, ' (Rattachement automatique)', ''), ')')
                        ELSE 
                            libobs4
                        END
                    END
                )::VARCHAR AS observers, 
                a.flore_global_geom AS the_geom_local, 
                ST_TRANSFORM(a.flore_global_geom, 4326) AS the_geom_4326, 
                ST_TRANSFORM(a.flore_global_geom, 4326) AS the_geom_point,
                (CASE 
                    WHEN NULLIF(rel_altiinf, '')::INT < NULLIF(rel_altisup, '')::INT THEN rel_altiinf 
                    WHEN NULLIF(rel_altiinf, '')::INT = NULLIF(rel_altisup, '')::INT THEN rel_altiinf
                    WHEN NULLIF(rel_altiinf, '')::INT > NULLIF(rel_altisup, '')::INT THEN rel_altisup
                    ELSE NULL                
                END)::INT AS alti_min,
                (CASE 
                    WHEN NULLIF(rel_altiinf, '')::INT < NULLIF(rel_altisup, '')::INT THEN rel_altisup 
                    WHEN NULLIF(rel_altiinf, '')::INT = NULLIF(rel_altisup, '')::INT THEN rel_altisup
                    WHEN NULLIF(rel_altiinf, '')::INT > NULLIF(rel_altisup, '')::INT THEN rel_altiinf
                    ELSE NULL                
                END)::INT AS alti_max,
                CASE 
                    WHEN codenombre = '1' OR codenombre LIKE '1;%' THEN 1 
                    WHEN codenombre = '2' OR codenombre LIKE '2;%' THEN 11
                    WHEN codenombre = '3' OR codenombre LIKE '3;%' THEN 101
                    WHEN codenombre = '4' OR codenombre LIKE '4;%' THEN 1001
                    WHEN codenombre = '5' OR codenombre LIKE '5;%' THEN 10000
                    ELSE NULL                
                END AS count_min, 
                CASE 
                    WHEN codenombre = '1' OR codenombre LIKE '%;1' THEN 10 
                    WHEN codenombre = '2' OR codenombre LIKE '%;2' THEN 100
                    WHEN codenombre = '3' OR codenombre LIKE '%;3' THEN 1000
                    WHEN codenombre = '4' OR codenombre LIKE '%;4' THEN 10000
                    WHEN codenombre = '5' OR codenombre LIKE '%;5' THEN 10000
                    ELSE NULL
                END AS count_max, 
                CASE 
                    WHEN miseenherbier = TRUE THEN 'Conservatoire Botanique National Alpin (Herbier)'
                    ELSE NULL
                END AS non_digital_proof, 
                -- a.UNDEFINED::TEXT AS digital_proof, 
                -- a.UNDEFINED::TEXT AS sample_number_proof, 
                -- a.UNDEFINED::VARCHAR AS determiner, 
                NULLIF(str_comment, '')::VARCHAR AS comment_description, 
                NULLIF(CONCAT_WS(' ', NULLIF(rel_commsta, ''), NULLIF(comrh, ''), NULLIF(rel_commilieu, '')), '')::VARCHAR AS comment_context, 
                -- a.UNDEFINED::VARCHAR AS validator, 
                -- a.UNDEFINED::TEXT AS validation_comment, 
                -- a.UNDEFINED::TIMESTAMP AS meta_validation_date, 
                CASE 
                    WHEN miseenherbier = TRUE THEN ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr')
                    ELSE gn_synthese.get_default_nomenclature_value('STATUT_OBS')
                END AS id_nomenclature_observation_status, 
                gn_synthese.get_default_nomenclature_value('TYP_INF_GEO'::character varying) AS id_nomenclature_info_geo_type, 
                gn_synthese.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying) AS id_nomenclature_geo_object_nature, 
                gn_synthese.get_default_nomenclature_value('METH_OBS'::character varying) AS id_nomenclature_obs_meth, 
                gn_synthese.get_default_nomenclature_value('STATUT_BIO'::character varying) AS id_nomenclature_bio_status, 
                gn_synthese.get_default_nomenclature_value('TECHNIQUE_OBS'::character varying) AS id_nomenclature_obs_technique, 
                gn_synthese.get_default_nomenclature_value('NATURALITE'::character varying) AS id_nomenclature_naturalness, 
                gn_synthese.get_default_nomenclature_value('STADE_VIE'::character varying) AS id_nomenclature_life_stage, 
                CASE 
                    WHEN miseenherbier = TRUE THEN ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '1') -- 1 = Oui
                    ELSE gn_synthese.get_default_nomenclature_value('PREUVE_EXIST')
                END AS id_nomenclature_exist_proof, 
                gn_synthese.get_default_nomenclature_value('METH_DETERMIN'::character varying) AS id_nomenclature_determination_method, 
                gn_synthese.get_default_nomenclature_value('ETA_BIO'::character varying) AS id_nomenclature_bio_condition, 
                gn_synthese.get_default_nomenclature_value('SEXE'::character varying) AS id_nomenclature_sex,
                gn_synthese.get_default_nomenclature_value('DEE_FLOU'::character varying) AS id_nomenclature_blurring, 
                gn_synthese.get_default_nomenclature_value('NIV_PRECIS'::character varying) AS id_nomenclature_diffusion_level, 
                gn_synthese.get_default_nomenclature_value('STATUT_SOURCE'::character varying) AS id_nomenclature_source_status, 
                gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying) AS id_nomenclature_sensitivity, 
                gn_synthese.get_default_nomenclature_value('STATUT_VALID'::character varying) AS id_nomenclature_valid_status, 
                gn_synthese.get_default_nomenclature_value('TYP_GRP'::character varying) AS id_nomenclature_grp_typ, 
                CASE 
                    WHEN LENGTH(codenombre) = 0 THEN gn_synthese.get_default_nomenclature_value('TYP_DENBR')::INT
                    WHEN codenombre IS NULL THEN gn_synthese.get_default_nomenclature_value('TYP_DENBR')::INT
                    ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')::INT
                END AS id_nomenclature_type_count, 
                CASE 
                    WHEN LENGTH(codenombre) = 0 THEN gn_synthese.get_default_nomenclature_value('OBJ_DENBR')
                    WHEN codenombre IS NULL THEN gn_synthese.get_default_nomenclature_value('OBJ_DENBR')
                    ELSE ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND')
                END AS id_nomenclature_obj_count, 
                -- a.UNDEFINED::CHAR AS last_action, 
                a.rel_datemodif::TIMESTAMP AS meta_update_date, 
                a.rel_datecreatf::TIMESTAMP AS meta_create_date
            FROM imports_cbna.flore_v20190124 AS a 
            WHERE (a.uuidreleve_flore_sta IS NOT NULL AND a.uuidreleve_flore_sta != '' AND CHAR_LENGTH(a.uuidreleve_flore_sta) = 32) 
                AND (a.uuidreleve_flore_str IS NOT NULL AND a.uuidreleve_flore_str != '' AND CHAR_LENGTH(a.uuidreleve_flore_str) = 32) 
                AND (a.taxref_cd_nom < 1000000 AND a.taxref_cd_nom > 0 AND a.taxref_cd_nom NOT IN (132062, 134102, 47565, 105772) )
                AND (a.idreleve_flore_global NOT IN (5989093)) 
            ORDER BY entity_source_pk_value ASC 
            LIMIT step
            OFFSET offsetCnt;
        offsetCnt := offsetCnt + 500000 ;
        RAISE NOTICE 'offsetCnt: %', offsetCnt;
    END LOOP;
END; $$
-- Problème avec : 5989093 dont l'UUID "uuidreleve_flore_str" n'est pas défini et qui bloque la requête malgré le WHERE