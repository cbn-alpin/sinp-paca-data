BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing data in GeoNature DB'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing DS_PUBLIQUE nomenclatures'
INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
        'Re',
        'Publique Régie',
        'Publique régie',
        'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
        'Publique régie',
        'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
        'SINP',
        'Validé',
        0,
        '002.003',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')
            AND tn.cd_nomenclature = 'Re'
    ) ;

INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
        'Ac',
        'Publique acquise',
        'Publique acquise',
        'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
        'Publique acquise',
        'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
        'SINP',
        'Validé',
        0,
        '002.004',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')
            AND tn.cd_nomenclature = 'Ac'
    ) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing STATUT_BIO nomenclatures'
INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO'),
        '10',
        'Passage en vol',
        'Passage en vol',
        'Passage en vol : Indique que l''individu est de passage et en vol.',
        'Passage en vol',
        'Passage en vol : Indique que l''individu est de passage et en vol.',
        'SINP',
        'Gelé',
        0,
        '013.010',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')
            AND tn.cd_nomenclature = '10'
    ) ;

INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO'),
        '8',
        'Chasse / alimentation',
        'Chasse / alimentation',
        'Chasse / alimentation : Indique que l''individu est sur une zone qui lui permet de chasser ou de s''alimenter.',
        'Chasse / alimentation',
        'Chasse / alimentation : Indique que l''individu est sur une zone qui lui permet de chasser ou de s''alimenter.',
        'SINP',
        'Gelé',
        0,
        '013.008',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')
            AND tn.cd_nomenclature = '8'
    ) ;

INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO'),
        '6',
        'Halte migratoire',
        'Halte migratoire',
        'Halte migratoire : Indique que l''individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte.',
        'Halte migratoire',
        'Halte migratoire : Indique que l''individu procède à une halte au cours de sa migration, et a été découvert sur sa zone de halte.',
        'SINP',
        'Gelé',
        0,
        '013.006',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')
            AND tn.cd_nomenclature = '6'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
