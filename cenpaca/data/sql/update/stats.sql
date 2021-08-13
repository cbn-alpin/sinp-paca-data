\echo '-------------------------------------------------------------------------------'
\echo 'Display stats for: ':'importTable'
\echo 'Rights: DB owner'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'INSERT:'
SELECT count(*)
FROM gn_imports.:importTable
WHERE meta_last_action = 'I' ;


\echo '-------------------------------------------------------------------------------'
\echo 'UPDATE:'
SELECT count(*)
FROM gn_imports.:importTable
WHERE meta_last_action = 'U' ;


\echo '-------------------------------------------------------------------------------'
\echo 'DELETE:'
SELECT count(*)
FROM gn_imports.:importTable
WHERE meta_last_action = 'D' ;
