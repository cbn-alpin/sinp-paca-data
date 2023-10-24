-- Query to extracts Papilionoidea taxons for PACA with sensitive data !
-- Usage (from local computer): cat ./dep13_taxons.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_taxons_dep13.csv
-- The CSV file should contain:  lines.
\timing off
COPY (
    SELECT DISTINCT
        t2.cd_ref AS cd_ref,
        t2.nom_valide AS nom_valide,
        t2.cd_ref AS cd_ref,
        t2.nom_vern AS nom_vern,
        t2.group1_inpn AS group1_inpn,
        t2.group2_inpn AS group2_inpn,
        t2.regne AS regne,
        t2.phylum AS phylum,
        t2.classe AS classe,
        t2.ordre AS ordre,
        t2.famille AS famille,
        t2.id_rang AS id_rang,
        summary.nb_obs AS nb_obs,
        summary.date_min AS date_min,
        summary.date_max AS date_max
    FROM gn_synthese.synthese AS s
        JOIN taxonomie.taxref AS t1
            ON t1.cd_nom = s.cd_nom
        JOIN taxonomie.taxref AS t2
            ON t1.cd_ref = t2.cd_nom
        JOIN (
            SELECT
                st.cd_ref,
                count(DISTINCT ss.id_synthese) AS nb_obs,
                min(ss.date_min) AS date_min,
                max(ss.date_max) AS date_max
            FROM gn_synthese.synthese AS ss
                JOIN taxonomie.taxref AS st
                    ON st.cd_nom = ss.cd_nom
            WHERE st.famille IN ('Papilionidae', 'Hedylidae', 'Hesperiidae', 'Pieridae', 'Riodinidae', 'Lycaenidae', 'Nymphalidae')
            GROUP BY st.cd_ref
        ) AS summary
            ON summary.cd_ref = t2.cd_ref
    WHERE t1.famille IN ('Papilionidae', 'Hedylidae', 'Hesperiidae', 'Pieridae', 'Riodinidae', 'Lycaenidae', 'Nymphalidae')
) TO stdout
WITH (format csv, header, delimiter E'\t');
