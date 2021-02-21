BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add CEN-PACA as organism'
INSERT INTO utilisateurs.bib_organismes (
    nom_organisme,
    adresse_organisme,
    cp_organisme,
    ville_organisme,
    tel_organisme,
    fax_organisme,
    email_organisme,
    url_organisme,
    url_logo
)
SELECT
    'CEN-PACA',
    'Immeuble Atrium, Bât. B. 4, avenue Marcel Pagnol',
    '13100',
    'Aix-en-Provence',
    '04 42 20 03 83',
    '',
    'contact@cen-paca.org',
    'http://www.cen-paca.org/',
    NULL
WHERE NOT EXISTS (
    SELECT 'X'
    FROM utilisateurs.bib_organismes AS bo
    WHERE bo.nom_organisme = 'CEN-PACA'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Create acquisition framework for CEN-PACA'
INSERT INTO gn_meta.t_acquisition_frameworks (
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    acquisition_framework_parent_id,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date
)
SELECT
    'f23b1d31-a33a-454e-a13a-4b8df249d0d4',
    'Observations Faune (CEN-PACA)',
    'Ensemble des observations Faune transmises par le CEN-PACA dans le cadre du SINP régional.',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '5'),-- Régional
    'Région Sud (Provence-Alpes-Côte d''Azur).',
    'Observations, Faune, Région, Sud, PACA, Provence, Alpes, Côte d''Azur.',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '3'),-- Mélange public et privé
    'Silene est la plateforme de la région Sud (PACA) du Système d’Information de l’iNventaire du Patrimoine naturel (SINP).',
    'Faune',
    NULL,
    false,
    '2007-01-01',
    NULL
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_meta.t_acquisition_frameworks AS tafe
    WHERE tafe.unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and actor'
INSERT INTO gn_meta.cor_acquisition_framework_actor (
    id_acquisition_framework,
    id_organism,
    id_nomenclature_actor_role
) VALUES (
    (
        SELECT id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks
        WHERE unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
    ),
    (
        SELECT id_organisme
        FROM utilisateurs.bib_organismes
        WHERE nom_organisme = 'CEN-PACA'
    ),
    ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1') -- Contact principal
)
ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and objectifs'
INSERT INTO gn_meta.cor_acquisition_framework_objectif (
    id_acquisition_framework,
    id_nomenclature_objectif
) VALUES
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '1') -- Inventaire espèce
    ),
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '7') -- Regroupements et autres études
    )
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_objectif DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and SINP "volet"'
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
    id_acquisition_framework,
    id_nomenclature_voletsinp
) VALUES
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
        ),
        ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1') -- Terre
    )
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_voletsinp DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Create CEN PACA datasets in acquisition framework'
INSERT INTO gn_meta.t_datasets (
    unique_dataset_id,
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    active,
    validable
)
SELECT
    '8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6',
    (
        SELECT id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks
        WHERE unique_acquisition_framework_id = 'f23b1d31-a33a-454e-a13a-4b8df249d0d4'
    ),
    'Données faune du CEN-PACA',
    'DFCP',
    'Ensemble des données faune du CEN-PACA pour test.',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'), -- Occurrences de Taxons
    'Faune, test, CEN-PACA.',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '7.1'), -- Regroupement de données
    NULL,
    NULL,
    NULL,
    NULL,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'), -- Observation directe
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'NSP'), -- Ne sait pas
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'NSP'), -- Ne sait pas
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'), -- Dataset
    true,
    true
WHERE NOT EXISTS(
    SELECT 'X'
    FROM gn_meta.t_datasets AS td
    WHERE td.unique_dataset_id = '8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6'
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between datasets and actors'
INSERT INTO gn_meta.cor_dataset_actor (
    id_dataset,
    id_organism,
    id_nomenclature_actor_role
) VALUES
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6'
        ),
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'CEN-PACA'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1') -- Contact principal
    )
ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_organism DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert link between datasets and modules'
INSERT INTO gn_commons.cor_module_dataset (
    id_module,
    id_dataset
) VALUES
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code ILIKE 'SYNTHESE'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6'
        )
    )
ON CONFLICT ON CONSTRAINT pk_cor_module_dataset DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
