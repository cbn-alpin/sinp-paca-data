WITH taxo_groups AS (
    SELECT group_name, cd_refs
    FROM (
        VALUES

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
                        AND ordre = 'Orthoptera'
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
                        AND phylum NOT IN (
                            'Arthropoda', 'Annelida', 'Cnidaria', 'Mollusca', 'Platyhelminthes',
                            'Chordata'
                        )
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
groups_counts AS (
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
)
SELECT
    group_name AS groupe,
    taxon_nbr AS taxon_nbre,
    obs_nbr AS obs_nbre
FROM (
    SELECT
        group_name,
        taxon_nbr,
        obs_nbr,
        0 AS sort_order
    FROM groups_counts


       UNION

       SELECT
           'Total' AS group_name,
           SUM(taxon_nbr) AS taxon_nbr,
           SUM(obs_nbr) AS obs_nbr,
           1 AS sort_order
       FROM groups_counts
   ) AS counts_and_total
ORDER BY sort_order, group_name ;
