-- Droits d'éxecution nécessaire : DB OWBER
-- Update modules infos
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Add EXPORTS module if not exists'
INSERT INTO gn_commons.t_modules (
    module_code,
    module_label,
    module_picto,
    module_desc,
    module_path,
    module_target,
    active_frontend,
    active_backend,
    module_doc_url
)
    SELECT
        'EXPORTS',
        'Exports',
        'fa-cloud-download',
        'Module Exports - Télécharger les données.',
        'exports',
        '_self',
        true,
        true,
        'https://github.com/PnX-SI/gn_module_export'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_commons.t_modules AS tm
        WHERE tm.module_code = 'EXPORTS'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Update SYNTHESE module infos'
UPDATE gn_commons.t_modules SET
    module_label = 'Observations',
    module_desc = 'Module Synthèse - Accès aux observations.'
WHERE module_code = 'SYNTHESE' ;


\echo '----------------------------------------------------------------------------'
\echo 'Set modules order'
UPDATE gn_commons.t_modules SET module_order = 1 WHERE module_code = 'GEONATURE' ;
UPDATE gn_commons.t_modules SET module_order = 2 WHERE module_code = 'ADMIN' ;
UPDATE gn_commons.t_modules SET module_order = 3 WHERE module_code = 'EXPORTS' ;
UPDATE gn_commons.t_modules SET module_order = 4 WHERE module_code = 'METADATA' ;
UPDATE gn_commons.t_modules SET module_order = 5 WHERE module_code = 'SYNTHESE' ;

COMMIT;
