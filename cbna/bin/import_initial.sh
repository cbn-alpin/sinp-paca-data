#!/bin/bash
# Encoding : UTF-8
# Import in GeoNature Database the CBNA Flore Data

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${cbna_log_imports}"
    checkSuperuser

    local readonly commands=("psql" "pg_restore")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "CBNA test dataset import script started at: ${fmt_time_start}"

    downloadCbnaFloreExport
    importTerritoryArea
    cd "${module_dir}/"
    prepareDbBeforeRestoring
    restoreCbnaFloreExport
    cleanAfterRestoring
    buildImportTable
    addHelpersFunctions
    addMetaData
    prepareSynthese
    importSyntheseData
    maintainDb

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadCbnaFloreExport() {
    printMsg "Downloading CBNA flora data ${cbna_import_version} archive..."

    if [[ ! -f "${raw_dir}/${cbna_filename_archive}" ]]; then
        curl -X POST https://content.dropboxapi.com/2/files/download \
            --header "Authorization: Bearer ${cbna_dropbox_token}" \
            --header "Dropbox-API-Arg: {\"path\": \"${cbna_dropbox_dir}/${cbna_filename_archive}\"}" \
            -o "${raw_dir}/${cbna_filename_archive}"
     else
        printVerbose "Archive file \"${cbna_filename_archive}\" already downloaded." ${Gra}
    fi
}

function importTerritoryArea() {
    local verbose_option="$([[ ${verbose} ]] && echo '-v' || echo '')"
    ${root_dir}/area/bin/initialize.sh --remove-outside_areas false --id "${cbna_sinp_region_id}" "${verbose_option}"
}

function prepareDbBeforeRestoring() {
    printMsg "Preparing database before restore raw CBNA data..."

    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v originSchema="${cbna_schema_origin}" \
            -v importSchema="${cbna_schema_import}" \
            -v originTable="${cbna_table_origin}" \
            -f "${sql_dir}/initial/001_before_restore_origin_table.sql"
}

function restoreCbnaFloreExport() {
    printMsg "Restoring raw CBNA data ..."

    /usr/bin/pg_restore --exit-on-error --verbose --jobs "${pg_restore_jobs}" \
        --host "${db_host}" --port "${db_port}" --username "${db_user}" --dbname "${db_name}" \
        --schema "${cbna_schema_origin}" --table "${cbna_table_origin}" --no-acl --no-owner \
        "${raw_dir}/${cbna_filename_archive}"
}

function cleanAfterRestoring() {
    printMsg "Renaming restored CBNA data table to source ..."

    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v originSchema="${cbna_schema_origin}" \
            -v importSchema="${cbna_schema_import}" \
            -v originTable="${cbna_table_origin}" \
            -v sourceTable="${cbna_table_source}" \
            -f "${sql_dir}/initial/002_after_restore_origin_table.sql"
}

function buildImportTable() {
    printMsg "Building import CBNA data table from source table ..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v importSchema="${cbna_schema_import}" \
            -v sourceTable="${cbna_table_source}" \
            -v importTable="${cbna_table_import}" \
            -v sinpRegId="${cbna_sinp_region_id}" \
            -f "${sql_dir}/initial/003_build_import_table.sql"
}

function addHelpersFunctions() {
    printMsg "Adding helpers functions ..."

    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_dir}/initial/004_add_helpers_functions.sql"
}

function addMetaData() {
    printMsg "Adding meta data ..."

    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/initial/005_add_metadata.sql"
}

function prepareSynthese() {
    printMsg "Preparing GeoNature database before deleting data into syntese table ..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_before_delete.sql"

    printVerbose "Remove if necessary previous data from synthese"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/initial/006_synthese_clean.sql"

    printMsg "Restoring GeoNature database after deleting data into syntese table ..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_after_delete.sql"
}

function importSyntheseData() {
    printMsg "Preparing database before insert into syntese table ..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_before_insert.sql"

    printMsg "Importing CBNA data into synthese ..."
    local readonly sql_file="${sql_dir}/initial/007_synthese_insert.sql"
    local readonly tmp_sql_file="${sql_dir}/initial/007_synthese_insert.tmp.sql"

    printVerbose "Copy SQL script"
    cp "${sql_file}" "${tmp_sql_file}"

    printVerbose "Replace variables in PGPSQL script"
    sed -e "s/^\(.*\){{importSchema}}\(.*\)$/\1${cbna_schema_import}\2/" \
        -i "${tmp_sql_file}"
    sed -e "s/^\(.*\){{importTable}}\(.*\)$/\1${cbna_table_import}\2/" \
        -i "${tmp_sql_file}"

    printVerbose "Execute PGPSQL script"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -f "${tmp_sql_file}"

    printMsg "Restoring database after insert into syntese table ..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_after_insert.sql"
}

function maintainDb() {
    printMsg "Executing maintenance operations on synthese table ..."

    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_maintenance.sql"
}

main "${@}"
