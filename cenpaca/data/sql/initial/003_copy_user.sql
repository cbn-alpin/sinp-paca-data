BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into roles'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';
SET search_path = utilisateurs;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove "tmp_users" table if already exists'
DROP TABLE IF EXISTS tmp_users ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_users" table from "t_roles"'
CREATE TABLE tmp_users AS
TABLE t_roles
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute "tmp_organisms" to GeoNature DB owner'
ALTER TABLE tmp_users OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to tmp_users'
COPY tmp_users (
    uuid_role,
    identifiant,
    prenom_role,
    nom_role,
    email,
    id_organisme,
    remarques,
    active,
    champs_addi,
    date_insert,
    date_update
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy "tmp_users" data to "t_roles" if not exist'
INSERT INTO t_roles(
    uuid_role,
    identifiant,
    prenom_role,
    nom_role,
    email,
    id_organisme,
    remarques,
    active,
    champs_addi,
    date_insert,
    date_update
)
SELECT
    uuid_role,
    identifiant,
    prenom_role,
    nom_role,
    email,
    id_organisme,
    remarques,
    active,
    champs_addi,
    date_insert,
    date_update
FROM tmp_users AS tmp
WHERE NOT EXISTS (
    SELECT 'X'
    FROM t_roles AS tr
    WHERE tr.identifiant = tmp.identifiant
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
