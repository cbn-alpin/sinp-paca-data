BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into acquisition frameworks'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';
SET search_path = gn_meta;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "tmp_acquisition_frameworks" table if already exists'
DROP TABLE IF EXISTS tmp_acquisition_frameworks ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_users" table from "t_roles"'
CREATE TABLE tmp_acquisition_frameworks AS
TABLE t_acquisition_frameworks
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "tmp_acquisition_frameworks" to GeoNature DB owner'
ALTER TABLE tmp_acquisition_frameworks OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add new fields to tmp_acquisition_frameworks table to store infos about correspondence tables'
ALTER TABLE tmp_acquisition_frameworks
    ALTER COLUMN acquisition_framework_parent_id TYPE varchar(255),
    ADD COLUMN cor_objectifs varchar(255) [],
    ADD COLUMN cor_voletsinp varchar(255) [],
    ADD COLUMN cor_publications jsonb,
    ADD COLUMN cor_actors_organism varchar(255) [][],
    ADD COLUMN cor_actors_user varchar(255) [][]
;

ALTER TABLE tmp_acquisition_frameworks
    RENAME COLUMN acquisition_framework_parent_id TO parent_code ;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to tmp_acquisition_frameworks'
COPY tmp_acquisition_frameworks (
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    parent_code,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date,
    cor_objectifs,
    cor_voletsinp,
    cor_actors_organism,
    cor_actors_user,
    cor_publications,
    meta_create_date,
    meta_update_date
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy PARENT "tmp_acquisition_frameworks" data to "t_acquisition_frameworks" if not exist'
INSERT INTO t_acquisition_frameworks(
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
    acquisition_framework_end_date,
    meta_create_date,
    meta_update_date
)
SELECT
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    NULL,
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date,
    meta_create_date,
    meta_update_date
FROM tmp_acquisition_frameworks AS tmp
WHERE NOT EXISTS (
        SELECT 'X'
        FROM t_acquisition_frameworks AS taf
        WHERE taf.acquisition_framework_name = tmp.acquisition_framework_name
    )
    AND tmp.is_parent = True;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CHILDREN "tmp_acquisition_frameworks" data to "t_acquisition_frameworks" if not exist'
INSERT INTO t_acquisition_frameworks(
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
    acquisition_framework_end_date,
    meta_create_date,
    meta_update_date
)
SELECT
    unique_acquisition_framework_id,
    acquisition_framework_name,
    acquisition_framework_desc,
    id_nomenclature_territorial_level,
    territory_desc,
    keywords,
    id_nomenclature_financing_type,
    target_description,
    ecologic_or_geologic_target,
    (
        SELECT taf_parent.id_acquisition_framework
        FROM t_acquisition_frameworks AS taf_parent
        WHERE taf_parent.acquisition_framework_name = tmp.parent_code
    ),
    is_parent,
    acquisition_framework_start_date,
    acquisition_framework_end_date,
    meta_create_date,
    meta_update_date
FROM tmp_acquisition_frameworks AS tmp
WHERE NOT EXISTS (
        SELECT 'X'
        FROM t_acquisition_frameworks AS taf
        WHERE taf.acquisition_framework_name = tmp.acquisition_framework_name
    )
    AND tmp.is_parent = False;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and objectifs'
INSERT INTO cor_acquisition_framework_objectif (
    id_acquisition_framework,
    id_nomenclature_objectif
)
    SELECT
	    gn_meta.get_id_acquisition_framework_by_name(tmp.acquisition_framework_name),
	    ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', UNNEST(tmp.cor_objectifs))
    FROM gn_meta.tmp_acquisition_frameworks AS tmp
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_objectif DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and SINP "volet"'
INSERT INTO cor_acquisition_framework_voletsinp (
    id_acquisition_framework,
    id_nomenclature_voletsinp
)
    SELECT
	    gn_meta.get_id_acquisition_framework_by_name(tmp.acquisition_framework_name),
	    ref_nomenclatures.get_id_nomenclature('VOLET_SINP', UNNEST(tmp.cor_voletsinp))
    FROM gn_meta.tmp_acquisition_frameworks AS tmp
ON CONFLICT ON CONSTRAINT pk_cor_acquisition_framework_voletsinp DO NOTHING ;

-- TODO: handle cor_publications

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and actor => ORGANISM'
INSERT INTO cor_acquisition_framework_actor (
    id_acquisition_framework,
    id_organism,
    id_nomenclature_actor_role
)
    SELECT
        gn_meta.get_id_acquisition_framework_by_name(tmp.acquisition_framework_name),
        utilisateurs.get_id_organism_by_name(elems ->> 0),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
    FROM gn_meta.tmp_acquisition_frameworks AS tmp,
        json_array_elements(array_to_json(tmp.cor_actors_organism)) elems
ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism DO NOTHING ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert link between acquisition framework and actor => USER'
INSERT INTO cor_acquisition_framework_actor (
    id_acquisition_framework,
    id_role,
    id_nomenclature_actor_role
)
    SELECT
        gn_meta.get_id_acquisition_framework_by_name(tmp.acquisition_framework_name),
        utilisateurs.get_id_role_by_identifier(elems ->> 0),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', elems ->> 1)
    FROM gn_meta.tmp_acquisition_frameworks AS tmp,
        json_array_elements(array_to_json(tmp.cor_actors_user)) elems
ON CONFLICT ON CONSTRAINT check_is_unique_cor_acquisition_framework_actor_role DO NOTHING ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
