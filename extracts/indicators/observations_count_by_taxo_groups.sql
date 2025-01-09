-- Script to export stats by taxonomic groups
-- Usage (from local computer): cat ./observations_count_by_taxo_groups.sql | ssh geonat@db-paca-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_taxo_groups_stats.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH taxo_groups AS (
        SELECT group_name, cd_refs
        FROM ( VALUES
            ('Animalia - Vertébrés - Mammifères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Mammifères'
                        AND ordre != 'Chiroptera'
                )
            ),
            ('Animalia - Vertébrés - Chiroptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Mammifères'
                        AND ordre = 'Chiroptera'
                )
            ),
            ('Animalia - Vertébrés - Oiseaux', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Oiseaux'
                )
            ),
            ('Animalia - Vertébrés - Reptiles', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Reptiles'
                )
            ),
            ('Animalia - Vertébrés - Amphibiens', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Amphibiens'
                )
            ),
            ('Animalia - Vertébrés - Poissons', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Chordata'
                        AND group2_inpn = 'Poissons'
                )
            ),
            ('Animalia - Invertébrés - Arachnides', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND classe = 'Arachnida'
                )
            ),
            ('Animalia - Invertébrés - Mollusques', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND group1_inpn = 'Mollusques'
                )
            ),
            ('Animalia - Invertébrés - Crustacés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND group2_inpn = 'Crustacés'
                )
            ),
            ('Animalia - Invertébrés - Autres arthropodes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND famille IN (
                            'Aeolothripidae', 'Amelidae', 'Amorphoscelidae', 'Anisolabididae',
                            'Arrhopalitidae', 'Bittacidae', 'Blaniulidae', 'Blattidae',
                            'Boreidae', 'Bourletiellidae', 'Callipodidae', 'Ceratophyllidae',
                            'Craspedosomatidae', 'Cryptopidae', 'Ctenophthalmidae',
                            'Cyphoderidae', 'Dignathodontidae', 'Ectobiidae', 'Embiidae',
                            'Empusidae', 'Entomobryidae', 'Eremiaphilidae', 'Forficulidae',
                            'Geophilidae', 'Glomeridae', 'Henicopidae', 'Himantariidae',
                            'Hypogastruridae', 'Hystrichopsyllidae', 'Inocelliidae',
                            'Isotomidae', 'Julidae', 'Kalotermitidae', 'Katiannidae',
                            'Labiduridae', 'Lepismatidae', 'Linotaeniidae', 'Lithobiidae',
                            'Machilidae', 'Macrosternodesmidae', 'Mantidae', 'Meinertellidae',
                            'Neanuridae', 'Neelidae', 'Odontellidae', 'Oligotomidae',
                            'Oncopoduridae', 'Onychiuridae', 'Panorpidae', 'Paradoxosomatidae',
                            'Pediculidae', 'Phlaeothripidae', 'Poduridae', 'Polydesmidae',
                            'Polyxenidae', 'Psocidae', 'Pulicidae', 'Raphidiidae',
                            'Rhinotermitidae', 'Rivetinidae', 'Schendylidae', 'Scolopendridae',
                            'Scutigeridae', 'Sialidae', 'Sminthuridae', 'Sminthurididae',
                            'Spongiphoridae', 'Stenopsocidae', 'Thripidae', 'Tomoceridae',
                            'Trogiidae', 'Tullbergiidae', 'Vermipsyllidae', 'Xenidae'
                        )
                )
            ),
            ('Animalia - Invertébrés - Coléoptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Coleoptera'
                )
            ),
            ('Animalia - Invertébrés - Odonates', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Odonata'
                )
            ),
            ('Animalia - Invertébrés - Orthoptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre in ('Orthoptera', 'Phasmatodea', 'Dictyoptera', 'Phasmida')
                )
            ),
            ('Animalia - Invertébrés - Diptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Diptera'
                )
            ),
            ('Animalia - Invertébrés - Neuroptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Neuroptera'
                )
            ),
            ('Animalia - Invertébrés - Hemiptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Hemiptera'
                )
            ),
            ('Animalia - Invertébrés - Hymenoptères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Hymenoptera'
                )
            ),
            ('Animalia - Invertébrés - Insectes aquatiques', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre IN ('Ephemeroptera', 'Trichoptera', 'Plecoptera')
                )
            ),
            ('Animalia - Invertébrés - Papillons de jour et zygènes', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Lepidoptera'
                        AND famille IN ('Papilionidae', 'Pieridae', 'Nymphalidae', 'Danaidae',
                            'Hesperiidae', 'Lycaenidae', 'Riodinidae', 'Zygaenidae')
                )
            ),
            ('Animalia - Invertébrés - Hétérocères', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum = 'Arthropoda'
                        AND ordre = 'Lepidoptera'
                        AND famille IN (
                            'Acanthopteroctetidae', 'Adelidae', 'Agathiphagidae', 'Alucitidae',
                            'Argyresthiidae', 'Attevidae', 'Autostichidae', 'Batrachedridae',
                            'Bedelliidae', 'Blastobasidae', 'Brachodidae', 'Brahmaeidae',
                            'Bucculatrigidae', 'Carposinidae', 'Castniidae', 'Choreutidae',
                            'Cimeliidae', 'Coleophoridae', 'Copromorphidae', 'Cosmopterigidae',
                            'Cossidae', 'Crambidae', 'Depressariidae', 'Douglasiidae', 'Drepanidae',
                            'Dryadaulidae', 'Elachistidae', 'Endromidae', 'Epermeniidae',
                            'Erebidae', 'Eriocottidae', 'Eriocraniidae', 'Euteliidae',
                            'Galacticidae', 'Gelechiidae', 'Geometridae', 'Glyphipterigidae',
                            'Gracillariidae', 'Hedylidae', 'Heliodinidae', 'Heliozelidae',
                            'Hepialidae', 'Heterogynidae', 'Hyblaeidae', 'Immidae', 'Incurvariidae',
                            'Lasiocampidae', 'Lecithoceridae', 'Limacodidae', 'Lyonetiidae',
                            'Lypusidae', 'Micropterigidae', 'Millieriidae', 'Momphidae',
                            'Nepticulidae', 'Noctuidae', 'Nolidae', 'Notodontidae', 'Oecophoridae',
                            'Opostegidae', 'Plutellidae', 'Praydidae', 'Prodoxidae', 'Psychidae',
                            'Pterolonchidae', 'Pterophoridae', 'Pyralidae', 'Roeslerstammiidae',
                            'Saturniidae', 'Schreckensteiniidae', 'Scythrididae', 'Scythropiidae',
                            'Sesiidae',  'Sphingidae', 'Stathmopodidae', 'Thyrididae', 'Tineidae',
                            'Tischeriidae', 'Tortricidae', 'Uraniidae', 'Urodidae', 'Xylorictidae',
                            'Yponomeutidae', 'Ypsolophidae'
                        )
                )
            ),
            ('Animalia - Autres', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum NOT IN ('Arthropoda', 'Mollusca','Chordata')
                )
            ),
            ('Fungi', ARRAY(
                SELECT DISTINCT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Fungi')
            ),
            ('Plantae - Trachéophytes', ARRAY(
                SELECT DISTINCT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Plantae'
                    AND group1_inpn = 'Trachéophytes')
            ),
            ('Plantae - Bryophytes', ARRAY(
                SELECT DISTINCT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Plantae'
                    AND group1_inpn = 'Bryophytes')
            ),
            ('Plantae - Algues', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Plantae'
                    AND group1_inpn = 'Algues')
            ),
            ('Plantae - Autres', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Plantae'
                    AND group1_inpn = 'Autres')
            ),
            ('Archaea', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Archaea')
            ),
            ('Bacteria', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Bacteria')
            ),
            ('Chromista', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Chromista')
            ),
            ('Protozoa', ARRAY(
                SELECT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Protozoa')
            )
        ) AS tg (group_name, cd_refs)
    ),
    taxo_groups_counts AS (
        SELECT
            r.group_name,
            COUNT(r.nbre) AS taxon_nbr,
            SUM(r.nbre) AS obs_nbr
        FROM (
                SELECT tg.group_name, COUNT(s.id_synthese) AS nbre
                FROM gn_synthese.synthese AS s
                    JOIN taxonomie.taxref AS t
                        ON s.cd_nom = t.cd_nom
                    JOIN taxo_groups AS tg
                        ON t.cd_ref = ANY(tg.cd_refs)
                GROUP BY tg.group_name, t.cd_ref
            ) AS r
        GROUP BY r.group_name
    ),
    final_taxo_groups as (
        SELECT
            'groupe' as group_type,
            group_name,
            taxon_nbr,
            obs_nbr,
            sort_order
        FROM (
                SELECT
                    group_name,
                    taxon_nbr,
                    obs_nbr,
                    0 AS sort_order
                FROM taxo_groups_counts

                UNION

                SELECT
                    'Total groupe' AS group_name,
                    SUM(taxon_nbr) AS taxon_nbr,
                    SUM(obs_nbr) AS obs_nbr,
                    1 AS sort_order
                FROM taxo_groups_counts
            ) AS counts_and_total
        ORDER BY sort_order, group_name
    ),
    meta_taxo_groups AS (
        SELECT
            group_name,
            cd_refs
        FROM (VALUES
            ('Animalia - Vertébrés', ARRAY(
                SELECT DISTINCT cd_ref
                FROM taxonomie.taxref
                WHERE regne = 'Animalia'
                    AND phylum = 'Chordata')
            ),
            ('Animalia - Invertébrés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum IN (
                            'Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes'
                        )
                )
            ),
            ('Animalia - Autres', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne = 'Animalia'
                        AND phylum NOT IN (
                            'Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes',
                            'Chordata'
                        )
                )
            ),
            ('Végétaux et associés', ARRAY(
                    SELECT DISTINCT cd_ref
                    FROM taxonomie.taxref
                    WHERE regne IN ('Fungi','Plantae','Archaea','Bacteria','Chromista','Protozoa')
                )
            )
        ) AS tg (group_name, cd_refs)
    ),
    meta_taxo_groups_counts AS (
        SELECT
            r.group_name,
            COUNT(r.nbre) AS taxon_nbr,
            SUM(r.nbre) AS obs_nbr
        FROM (
            SELECT tg.group_name, COUNT(s.id_synthese) AS nbre
            FROM gn_synthese.synthese AS s
                JOIN taxonomie.taxref AS t
                    ON s.cd_nom = t.cd_nom
                JOIN meta_taxo_groups AS tg
                    ON t.cd_ref = ANY(tg.cd_refs)
            GROUP BY tg.group_name, t.cd_ref
        ) AS r
        GROUP BY r.group_name
    ),
    final_meta_taxo_groups as (
        SELECT
            'meta groupe' as group_type,
            group_name,
            taxon_nbr,
            obs_nbr,
            sort_order
        FROM (
            SELECT
                group_name,
                taxon_nbr,
                obs_nbr,
                0 AS sort_order
            FROM meta_taxo_groups_counts

            UNION

            SELECT
                'Total meta groupe' AS group_name,
                SUM(taxon_nbr) AS taxon_nbr,
                SUM(obs_nbr) AS obs_nbr,
                1 AS sort_order
            FROM meta_taxo_groups_counts
        ) AS counts_and_total
        ORDER BY sort_order, group_name
    )
    SELECT
        group_type AS type_groupe,
        group_name AS groupe,
        taxon_nbr AS taxon_nbre,
        obs_nbr AS obs_nbre
    FROM (
            SELECT * FROM final_taxo_groups

            UNION

            SELECT * FROM final_meta_taxo_groups

            ORDER BY group_type, sort_order, group_name
        ) AS final_groups
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
