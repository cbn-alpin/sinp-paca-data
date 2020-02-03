CREATE OR REPLACE FUNCTION utilisateurs.get_id_organization(organizationUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_dataset from a dataset UUID
DECLARE idOrganization INTEGER;
BEGIN
  SELECT id_organisme INTO idOrganization
  FROM utilisateurs.bib_organismes
  WHERE uuid_organisme = organizationUuid;
  RETURN idOrganization;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION gn_meta.get_id_acquisition_framework(acquisitionFrameworkUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_acquisition_framework from a acquisition framework UUID
DECLARE idAcquisitionFramework INTEGER;
BEGIN
  SELECT id_acquisition_framework INTO idAcquisitionFramework
  FROM gn_meta.t_acquisition_frameworks
  WHERE unique_acquisition_framework_id = acquisitionFrameworkUuid;
  RETURN idAcquisitionFramework;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION gn_meta.get_id_dataset(datasetUuid UUID)
 RETURNS int AS
$BODY$
-- Function which return the id_dataset from a dataset UUID
DECLARE idDataset INTEGER;
BEGIN
  SELECT id_dataset INTO idDataset
  FROM gn_meta.t_datasets
  WHERE unique_dataset_id = datasetUuid;
  RETURN idDataset;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION gn_synthese.get_id_source(sourceName character varying)
 RETURNS int AS
$BODY$
-- Function which return the id_source from a source name
DECLARE idSource INTEGER;
BEGIN
  SELECT id_source INTO idSource
  FROM gn_synthese.t_sources
  WHERE name_source = sourceName;
  RETURN idSource;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;

-- +--------------------------------------------------------------------------------------------------------+
DELETE FROM utilisateurs.bib_organismes 
WHERE id_organisme = utilisateurs.get_id_organization('f80af199-2873-499a-b4e1-99078873fb47');

TRUNCATE TABLE gn_synthese.synthese CONTINUE IDENTITY CASCADE;

DELETE FROM gn_meta.cor_dataset_actor
WHERE id_dataset = gn_meta.get_id_dataset('b3988db2-2c94-4e1f-86f3-3a7184fc5f71');

DELETE FROM gn_meta.t_datasets 
WHERE unique_dataset_id = 'b3988db2-2c94-4e1f-86f3-3a7184fc5f71';

DELETE FROM gn_meta.cor_acquisition_framework_actor
WHERE id_acquisition_framework = gn_meta.get_id_acquisition_framework('54d26761-2859-49d2-bb87-ef97448c8a27');

DELETE FROM gn_meta.t_acquisition_frameworks 
WHERE unique_acquisition_framework_id = '54d26761-2859-49d2-bb87-ef97448c8a27';

-- +--------------------------------------------------------------------------------------------------------+

INSERT INTO utilisateurs.bib_organismes (
  uuid_organisme,
  nom_organisme,
  adresse_organisme,
  cp_organisme,
  ville_organisme,
  tel_organisme,
  fax_organisme,
  email_organisme,
  url_organisme,
  url_logo,
  id_parent
) VALUES (
  'f80af199-2873-499a-b4e1-99078873fb47',
  'Conservatoire Botanique National Alpin',
  'Domaine de Charance',
  '05000',
  'GAP',
  '04 92 53 56 82',
  '04 92 51 94 58',
  'accueil@cbn-alpin.fr',
  'http://www.cbn-alpin.fr',
  'http://www.cbn-alpin.fr/images/stories/habillage/logo-cbna.jpg',
  NULL
);

-- +--------------------------------------------------------------------------------------------------------+
INSERT INTO gn_meta.t_acquisition_frameworks (
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    acquisition_framework_parent_id,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date,
    meta_create_date,
    meta_update_date
) VALUES (
    '54d26761-2859-49d2-bb87-ef97448c8a27',
    'Base de données Flore du CBNA',
    'Ensemble des jeux de données présent dans la base de données Flore du CBNA.',
    355,
    NULL,
    'CBNA, flore',
    391,
    NULL,
    NULL,
    NULL,
    false,
    '1988-01-01',
    NULL,
    '2020-01-31 19:51:18.223',
    NULL
);

INSERT INTO gn_meta.cor_acquisition_framework_actor (
  id_acquisition_framework,
  id_role,
  id_organism,
  id_nomenclature_actor_role
) VALUES (
  gn_meta.get_id_acquisition_framework('54d26761-2859-49d2-bb87-ef97448c8a27'),
  NULL,
  utilisateurs.get_id_organization('f80af199-2873-499a-b4e1-99078873fb47'),
  365
);

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
    validable,
    meta_create_date,
    meta_update_date
) VALUES (
    'b3988db2-2c94-4e1f-86f3-3a7184fc5f71',
    gn_meta.get_id_acquisition_framework('54d26761-2859-49d2-bb87-ef97448c8a27'),
    'Ensemble des données flore du CBNA',
    'Flore CBNA',
    'Jeux de données global rassemblant toutes les données flore du CBNA.',
    326,
    NULL,
    false,
    true,
    443,
    NULL,
    NULL,
    NULL,
    NULL,
    413,
    77,
    74,
    323,
    true,
    true,
    '2020-01-31 19:55:42.492',
    NULL
);

INSERT INTO gn_meta.cor_dataset_actor (
  id_dataset,
  id_role,
  id_organism,
  id_nomenclature_actor_role
) VALUES (
  gn_meta.get_id_dataset('b3988db2-2c94-4e1f-86f3-3a7184fc5f71'),
  NULL,
  utilisateurs.get_id_organization('f80af199-2873-499a-b4e1-99078873fb47'),
  369
);


-- +--------------------------------------------------------------------------------------------------------+
DELETE FROM gn_synthese.t_sources 
WHERE name_source = 'CBNA - Flore globale';

INSERT INTO gn_synthese.t_sources (
    name_source, 
    desc_source
) VALUES (
    'CBNA - Flore globale', 
    'Données globales de la base Flore du CBNA.'
);
