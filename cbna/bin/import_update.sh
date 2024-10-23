#!/bin/bash
# Encoding : UTF-8
# Import some updated, deleted or new data in GeoNature Database the CBNA Flora Data.

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

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    downloadDataArchive
    extractArchive
    prepareDb

    buildTablePrefix

    parseCsv "source" "so"
    executeCopy "source"
    displayStats "source"
    executeUpgradeScript "source" "insert"
    executeUpgradeScript "source" "update"

    parseCsv "organism" "o"
    executeCopy "organism"
    displayStats "organism"
    executeUpgradeScript "organism" "insert"
    executeUpgradeScript "organism" "update"

    parseCsv "user" "u"
    executeCopy "user"
    displayStats "user"
    executeUpgradeScript "user" "insert"
    executeUpgradeScript "user" "update"

    parseCsv "acquisition framework" "af"
    executeCopy "acquisition framework"
    displayStats "acquisition framework"
    executeUpgradeScript "acquisition framework" "insert"
    executeUpgradeScript "acquisition framework" "update"

    parseCsv "dataset" "d"
    executeCopy "dataset"
    displayStats "dataset"
    executeUpgradeScript "dataset" "insert"
    executeUpgradeScript "dataset" "update"

    parseCsv "synthese" "s"
    executeCopy "synthese"
    displayStats "synthese"

    executeUpgradeScript "synthese" "insert"
    executeUpgradeScript "synthese" "update"

    reloadCorAreaSynthese

    executeUpgradeScript "synthese" "delete"
    executeUpgradeScript "dataset" "delete"
    executeUpgradeScript "acquisition framework" "delete"
    executeUpgradeScript "user" "delete"
    executeUpgradeScript "organism" "delete"
    executeUpgradeScript "source" "delete"

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadDataArchive() {
    printMsg "Downloading ${app_code^^} data archive..."

    if [[ ! -f "${raw_dir}/${cbna_filename_archive}" ]]; then
        downloadSftp "${sftp_user}" "${sftp_pwd}" \
            "${sftp_host}" "${sftp_port}" \
            "/${app_code}/${cbna_filename_archive}" "${raw_dir}/${cbna_filename_archive}"
     else
        printVerbose "Archive file \"${cbna_filename_archive}\" already downloaded." ${Gra}
    fi
}

function extractArchive() {
    printMsg "Extract import data CSV files..."

    if [[ -f "${raw_dir}/${cbna_filename_archive}" ]]; then
        if [[ ! -f "${raw_dir}/${cbna_filename_synthese}" ]]; then
            cd "${raw_dir}/"
            tar jxvf "${raw_dir}/${cbna_filename_archive}"
        else
            printVerbose "CSV files already extracted." ${Gra}
        fi
    fi
}

function prepareDb() {
    printMsg "Insert utils functions into GeoNature database..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/utils_functions.sql"
}

function buildTablePrefix() {
    table_prefix="${app_code}_${cbna_import_date//-/}"
}

function parseCsv() {
    if [[ $# -lt 2 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local type="${1,,}"
    local type_abbr="${2,,}"

    local data_type="${type// /_}"
    local data_type_abbr=$(echo "${type}" | sed 's/\(.\)[^ ]* */\1/g')
    if [[ "${#data_type_abbr}" = "1" ]]; then
        data_type_abbr="${data_type}"
    fi
    declare -n csv_file="cbna_filename_${data_type_abbr}"
    local csv_to_import="${csv_file%.csv}_rti.csv"

    # Exit if CSV file not found
    if ! [[ -f "${raw_dir}/${csv_file}" ]]; then
        return 0
    fi

    printMsg "Parse ${type^^} CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "${type_abbr}" \
            --config "${conf_dir}/parser_actions_update.ini" \
            "${raw_dir}/${csv_file}"
    else
        printVerbose "${type^^} CSV file already parsed." ${Gra}
    fi
}

function executeCopy() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local type="${1,,}"

    local data_type="${type// /_}"
    local data_type_abbr=$(echo "${type}" | sed 's/\(.\)[^ ]* */\1/g')
    if [[ "${#data_type_abbr}" = "1" ]]; then
        data_type_abbr="${data_type}"
    fi
    declare -n csv_file="cbna_filename_${data_type_abbr}"
    local csv_to_import="${csv_file%.csv}_rti.csv"

    # Exit if CSV file not found
    if ! [[ -f "${raw_dir}/${csv_file}" ]]; then
        return 0
    fi

    local table="${table_prefix}_${data_type}"
    local sql_file="${sql_shared_dir}/update/${data_type}/copy.sql"
    local psql_var="${data_type_abbr}ImportTable"

    printMsg "Copy ${type^^} in GeoNature database..."
    export PGPASSWORD="${db_super_pass}"; \
        psql -h "${db_host}" -U "${db_super_user}" -d "${db_name}" \
            -v "${psql_var}=${table}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_file}"
}

function displayStats() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local type="${1,,}"

    local data_type="${type// /_}"
    local table="${table_prefix}_${data_type}"
    local data_type="${type// /_}"
    local data_type_abbr=$(echo "${type}" | sed 's/\(.\)[^ ]* */\1/g')
    if [[ "${#data_type_abbr}" = "1" ]]; then
        data_type_abbr="${data_type}"
    fi
    declare -n csv_file="cbna_filename_${data_type_abbr}"

    # Exit if CSV file not found
    if ! [[ -f "${raw_dir}/${csv_file}" ]]; then
        return 0
    fi

    printMsg "Display ${type^^} stats..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v importTable="${table}" \
            -f "${sql_shared_dir}/update/stats.sql"

}

function executeUpgradeScript() {
    if [[ $# -lt 2 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local type="${1,,}"
    local action="${2,,}"

    local data_type="${type// /_}"
    local data_type_abbr=$(echo "${type}" | sed 's/\(.\)[^ ]* */\1/g')
    if [[ "${#data_type_abbr}" = "1" ]]; then
        data_type_abbr="${data_type}"
    fi
    declare -n csv_file="cbna_filename_${data_type_abbr}"

    # Exit if CSV file not found
    if ! [[ -f "${raw_dir}/${csv_file}" ]]; then
        return 0
    fi

    local table="${table_prefix}_${data_type}"
    local sql_file="${sql_shared_dir}/update/${data_type}/${action}.sql"
    local psql_var="${data_type_abbr}ImportTable"

    printMsg "${action^} ${type^^} in destination table..."
    export PGPASSWORD="${db_pass}"; \
        sed "s/\${${psql_var}}/${table}/g" "${sql_file}" | \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v "${psql_var}=${table}" \
            -f -
}

function reloadCorAreaSynthese() {
    printMsg "Reload cor_area_synthese table..."
    local table="${table_prefix}_synthese"
    local sql_file="${sql_shared_dir}/update/synthese/reload.sql"

    checkSuperuser
    export PGPASSWORD="${db_pass}"; \
        sed "s/\${syntheseImportTable}/${table}/g" "${sql_file}" | \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f -
}

main "${@}"
