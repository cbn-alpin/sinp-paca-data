-- Rights : SUPER USER
-- Initialize database before restoring CBNA data.
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create CBNA origin schema'
CREATE SCHEMA IF NOT EXISTS :originSchema;


\echo '----------------------------------------------------------------------------'
\echo 'Create CBNA import schema'
CREATE SCHEMA IF NOT EXISTS :importSchema;


\echo '----------------------------------------------------------------------------'
\echo 'Remove origin data table'
DROP TABLE IF EXISTS :originSchema.:originTable;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
