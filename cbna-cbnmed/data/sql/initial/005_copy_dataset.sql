BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into datasets'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';
SET search_path = gn_meta;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "tmp_datasets" table if already exists'
DROP TABLE IF EXISTS tmp_datasets ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_datasets" table from "t_datasets"'
CREATE TABLE tmp_datasets AS
TABLE t_datasets
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "tmp_datasets" to GeoNature DB owner'
ALTER TABLE tmp_datasets OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add new fields to tmp_datasets table to store infos about correspondence tables'
ALTER TABLE tmp_datasets
    ADD COLUMN cor_territory varchar(255) [][],
    ADD COLUMN cor_actors_organism varchar(255) [][],
    ADD COLUMN cor_actors_user varchar(255) [][]
;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to tmp_datasets'
COPY tmp_datasets (
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
    id_nomenclature_data_origin,-- Interverted order with id_nomenclature_collecting_method
    id_nomenclature_collecting_method,-- Interverted order with id_nomenclature_data_origin
    id_nomenclature_source_status,
    cor_territory,
    cor_actors_organism,
    cor_actors_user,
    meta_create_date,
    meta_update_date
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy "tmp_datasets" data to "t_datasets" if not exist'
INSERT INTO t_datasets (
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
    id_nomenclature_data_origin,
    id_nomenclature_collecting_method,
    id_nomenclature_source_status,
    meta_create_date,
    meta_update_date
)
SELECT
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
    id_nomenclature_data_origin,
    id_nomenclature_collecting_method,
    id_nomenclature_source_status,
    meta_create_date,
    meta_update_date
FROM tmp_datasets AS tmp
WHERE NOT EXISTS (
        SELECT 'X'
        FROM t_datasets AS td
        WHERE td.dataset_shortname = tmp.dataset_shortname
    ) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and territory'
INSERT INTO cor_dataset_territory (
    id_dataset,
    id_nomenclature_territory,
    territory_desc
)
    SELECT
        gn_meta.get_id_dataset_by_shortname(tmp.dataset_shortname),
        ref_nomenclatures.get_id_nomenclature('TERRITOIRE', elems ->> 0),
        elems ->> 1
    FROM gn_meta.tmp_datasets AS tmp,
        json_array_elements(array_to_json(tmp.cor_territory)) elems
ON CONFLICT ON CONSTRAINT pk_cor_dataset_territory DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between dataset and actor => ORGANISM'
INSERT INTO cor_dataset_actor (
    id_dataset,
    id_organism,
    id_nomenclature_actor_role
)
    SELECT
        gn_meta.get_id_dataset_by_shortname(tmp.dataset_shortname),
        utilisateurs.get_id_organism_by_name(elems ->> 0),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
    FROM gn_meta.tmp_datasets AS tmp,
        json_array_elements(array_to_json(tmp.cor_actors_organism)) elems
ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_organism DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between dataset and actor => USER'
INSERT INTO cor_dataset_actor (
    id_dataset,
    id_role,
    id_nomenclature_actor_role
)
    SELECT
        gn_meta.get_id_dataset_by_shortname(tmp.dataset_shortname),
        utilisateurs.get_id_role_by_identifier(elems ->> 0),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
    FROM gn_meta.tmp_datasets AS tmp,
        json_array_elements(array_to_json(tmp.cor_actors_user)) elems
ON CONFLICT ON CONSTRAINT check_is_unique_cor_dataset_actor_role DO NOTHING ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
