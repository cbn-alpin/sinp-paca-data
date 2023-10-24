-- Query to extracts status for Bouches-du-Rhône (13) with sensitive data included !
-- Usage (from local computer): cat ./dep13_status.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_status_dep13.csv
-- The CSV file should contain:  lines.
\timing off
COPY (
    WITH areas AS (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE area_code = '13'
            AND id_type = ref_geo.get_id_area_type_by_code('DEP')
    )
    SELECT DISTINCT
        s.cd_nom,
        t.cd_ref,
        t.nom_complet,
        t.nom_vern,
        bst.rq_statut,
        bsty.regroupement_type,
        bsty.lb_type_statut,
        bste.cd_sig,
        bste.full_citation,
        bste.doc_url,
        bsv.code_statut,
        bsv.label_statut
    FROM gn_synthese.synthese AS s
        JOIN gn_synthese.cor_area_synthese AS cas1
            ON s.id_synthese = cas1.id_synthese
        JOIN areas ON
            cas1.id_area = areas.id_area
        JOIN taxonomie.taxref AS t
            ON s.cd_nom = t.cd_nom
        JOIN gn_synthese.cor_area_synthese AS cas2
            ON s.id_synthese = cas2.id_synthese
        JOIN taxonomie.bdc_statut_cor_text_area AS bscta
            ON cas2.id_area = bscta.id_area
        JOIN taxonomie.bdc_statut_taxons AS bst
            ON t.cd_ref = bst.cd_ref
        JOIN taxonomie.bdc_statut_cor_text_values AS bsctv
            ON bst.id_value_text = bsctv.id_value_text
        JOIN taxonomie.bdc_statut_text AS bste
            ON (bste.id_text = bsctv.id_text AND bste.id_text = bscta.id_text AND bste.enable = true)
        JOIN taxonomie.bdc_statut_type AS bsty
            ON bste.cd_type_statut = bsty.cd_type_statut
        JOIN taxonomie.bdc_statut_values AS bsv
            ON bsctv.id_value = bsv.id_value
) TO stdout
WITH (format csv, header, delimiter E'\t');
