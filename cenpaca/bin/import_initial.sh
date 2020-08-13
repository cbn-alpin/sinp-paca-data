#!/bin/bash
# Encoding : UTF-8
# Import in GeoNature Database the CEN-PACA Fauna Data

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
    redirectOutput "${cp_log_imports}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "CEN-PACA test dataset import script started at: ${fmt_time_start}"

    downloadCenpacaDataArchive
    extractArchive
    addMetaData
    insertSource
    insertSynthese
    maintainDb

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadCenpacaDataArchive() {
    printMsg "Downloading CEN-PACA test data 2020-02-13 archive..."

    if [[ ! -f "${raw_dir}/${cp_filename_archive}" ]]; then
        curl -X POST https://content.dropboxapi.com/2/files/download \
            --header "Authorization: Bearer ${cp_dropbox_token}" \
            --header "Dropbox-API-Arg: {\"path\": \"${cp_dropbox_dir}/${cp_filename_archive}\"}" \
            > "${raw_dir}/${cp_filename_archive}"
     else
        printVerbose "Archive file \"${cp_filename_archive}\" already downloaded." ${Gra}
    fi
}

function extractArchive() {
    printMsg "Extracting import data CSV files..."

    if [[ -f "${raw_dir}/${cp_filename_archive}" ]]; then
        if [[ ! -f "${raw_dir}/${cp_filename_synthese}" ]]; then
            cd "${raw_dir}/"
            tar jxvf "${raw_dir}/${cp_filename_archive}"
        else
            printVerbose "CSV files already extracted." ${Gra}
        fi
    fi
}

function addMetaData() {
    # TODO: instead of sql file use import-parser with several CSV files
    printMsg "Inserting metadata into GeoNature database..."

    export PGPASSWORD="${db_pass}"; \    printMsg "Downloading CEN-PACA test data 2020-02-13 archive..."
    if [[ ! -f "${raw_dir}/${cp_filename_archive}" ]]; then
        curl -X POST https://content.dropboxapi.com/2/files/download \
            --header "Authorization: Bearer ${cp_dropbox_token}" \
            --header "Dropbox-API-Arg: {\"path\": \"${cp_dropbox_dir}/${cp_filename_archive}\"}" \
            > "${raw_dir}/${cp_filename_archive}"
     else
        printVerbose "Archive file \"${cp_filename_archive}\" already downloaded." ${Gra}
    fi

        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/initial/001_initialize_meta.sql"
}

function insertSource() {
    local csv_to_import="${cp_filename_source%.csv}_rti.csv"

    printMsg "Parsing SOURCE CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py --type "so" "${raw_dir}/${cp_filename_source}"
    else
        printVerbose "SOURCE CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting sources data into GeoNature database..."
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/002_copy_source.sql"
}

function insertSynthese() {
    local csv_to_import="${cp_filename_synthese%.csv}_rti.csv"

    printMsg "Parsing SYNTHESE CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py --type "s" "${raw_dir}/${cp_filename_synthese}"
    else
        printVerbose "SYNTHESE CSV file already parsed." ${Gra}
    fi

    printMsg "Preparing GeoNature database before insert into syntese table ..."
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_before_insert.sql"

    printMsg "Inserting synthese data into GeoNature database..."
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/003_copy_synthese.sql"

    printMsg "Restoring GeoNature database after insert into syntese table ..."
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_after_insert.sql"
}

function maintainDb() {
    printMsg "Executing database maintenance on updated tables..."

    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_dir}/initial/004_maintenance.sql"
}

main "${@}"
