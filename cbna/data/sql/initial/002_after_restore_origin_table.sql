-- Rights : SUPER USER
-- Rename origin CBNA data table.
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Remove source table'
DROP TABLE IF EXISTS :importSchema.:sourceTable;


\echo '----------------------------------------------------------------------------'
\echo 'Move restored CBNA orign data table to import schema'
ALTER TABLE :originSchema.:originTable SET SCHEMA :importSchema ;


\echo '----------------------------------------------------------------------------'
\echo 'Rename CBNA orign data table to source'
ALTER TABLE :importSchema.:originTable RENAME TO :sourceTable ;


\echo '----------------------------------------------------------------------------'
\echo 'Drop restored CBNA origin schema'
DROP SCHEMA :originSchema ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
