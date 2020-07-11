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
    redirectOutput "${cp_log_imports}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Install CEN-PACA test dataset script started at: ${fmt_time_start}"

    printInfo "Downloading CEN-PACA test data 2020-02-13 archive..."
    local archive_filename="${cp_data_filename}.tar.bz2"
    if [[ ! -f "${raw_dir}/${archive_filename}" ]]; then
        rm -f "${raw_dir}/${archive_filename}"
        curl -X POST https://content.dropboxapi.com/2/files/download \
            --header "Authorization: Bearer ${cp_dropbox_token}" \
            --header "Dropbox-API-Arg: {\"path\": \"${cp_dropbox_dir}/${archive_filename}\"}" \
            > "${raw_dir}/${archive_filename}"
     else
        printVerbose "Archive file \"${archive_filename}\" already downloaded." ${Gra}
    fi


    printInfo "Extracting import data SQL file..."
    local sql_filename="${cp_data_filename}.sql"
    if [[ -f "${raw_dir}/${archive_filename}" ]]; then
        if [[ ! -f "${raw_dir}/${sql_filename}" ]]; then
            cd "${raw_dir}/"
            tar jxvf "${raw_dir}/${archive_filename}"
        else
            printVerbose "SQL file \"${sql_filename}\" already extracted." ${Gra}
        fi
    fi


    # printInfo "Executing import data SQL file..."
    # export PGPASSWORD="${db_pass}"; \
    #     psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
    #         -f "${raw_dir}/${sql_filename}"


    printInfo "Inserting metadata into GeoNature database..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/001_initialize_meta.sql"


    printInfo "Transfering data from temporary import table to GeoNature synthese..."
    local csv_filename="${cp_data_filename}.csv"
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v csvFilePath="${raw_dir}/${csv_filename}" \
            -f "${sql_dir}/002_copy_data.sql"

    #+----------------------------------------------------------------------------------------------------------+
    displayTimeElapsed
}

main "${@}"
