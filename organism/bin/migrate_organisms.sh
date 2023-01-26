#!/bin/bash
# Encoding : UTF-8
# Migrate DB GeoNature organisms to INPN organisms referentiel


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
     -f | --file: path to organisms CSV file. Columns : nom_valide, uuid_inpn, others columns with UUID to replace.
     -o | --old: comma separated string of old id_organism. Ex. : 12,125. Use with --new.
     -n | --new: string of id_organism to keep. Id organism used to replace all old id_organism. Ex. 54. Use with --old.
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
            "--file") set -- "${@}" "-f" ;;
            "--old") set -- "${@}" "-o" ;;
            "--new") set -- "${@}" "-n" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:f:o:n:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "f") organisms_csv_path="$(realpath ${OPTARG})" ;;
            "o") old_id_organism="${OPTARG}" ;;
            "n") new_id_organism="${OPTARG}" ;;
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
    redirectOutput "${mgno_log_file}"

    commands=("psql" "csvtool")
    checkBinary "${commands[@]}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} import script started at: ${fmt_time_start}"
    organisms_csv_path="${raw_dir}/${mgno_migrate_file}"

    if [[ -n ${organisms_csv_path-} ]]; then
        mergeOrganismsFromCsv
    elif [[ -n ${new_id_organism-} ]] && [[ -n ${old_id_organism-} ]] ; then
        executeMergeOrganismSql "${new_id_organism}" "${old_id_organism}"
    else
        parseScriptOptions
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function mergeOrganismsFromCsv() {
    local head="$(csvtool -t TAB head 1 "${organisms_csv_path}")"

    printMsg "Merging organisms from ${organisms_csv_path}"
    local tasks_done=0
    local line_nbr=0
    local tasks_count="$(($(csvtool height "${organisms_csv_path}") - 1))"
    while IFS= read -r line; do
        line_nbr=$((${line_nbr} + 1))

        nom_valide="$(printf "$head\n$line" | csvtool namedcol nom_valide - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        uuid_inpn="$(printf "$head\n$line" | csvtool namedcol uuid_inpn - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local uuid_cenpaca="$(printf "$head\n$line" | csvtool namedcol uuid_cenpaca - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local uuid_cbnmed="$(printf "$head\n$line" | csvtool namedcol uuid_cbnmed - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local uuid_cbna="$(printf "$head\n$line" | csvtool namedcol uuid_cbna - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

        printInfo $(printf %100s |tr " " "-")
        printInfo "Compute #${line_nbr} ${nom_valide} (${uuid_inpn}):"

        getIdByUuid "INPN" "${uuid_inpn}"
        id_inpn="${id}"
        getIdByUuid "CEN-PACA" "${uuid_cenpaca}"
        id_cenpaca="${id}"
        getIdByUuid "CBNMED" "${uuid_cbnmed}"
        id_cbnmed="${id}"
        getIdByUuid "CBNA" "${uuid_cbna}"
        id_cbna="${id}"

        # Get id_organism to keep !
        selected_id=""

        if [[ "${selected_id}" == "" ]] && [[ "${id_inpn}" != "" ]]; then
            selected_id="${id_inpn}"
            selected_orga="INPN"
            selected_uuid="${uuid_inpn}"
        fi

        if [[ "${selected_id}" == "" ]] && [[ "${id_cenpaca}" != "" ]]; then
            selected_id="${id_cenpaca}"
            selected_orga="CEN-PACA"
            selected_uuid="${uuid_cenpaca}"
        fi

        if [[ "${selected_id}" == "" ]] && [[ "${id_cbnmed}" != "" ]]; then
            selected_id="${id_cbnmed}"
            selected_orga="CBNMED"
            selected_uuid="${uuid_cbnmed}"
        fi

        if [[ "${selected_id}" == "" ]] && [[ "${id_cbna}" != "" ]]; then
            selected_id="${id_cbna}"
            selected_orga="CBNA"
            selected_uuid="${uuid_cbna}"
        fi

        # Merge and update database
        if [[ "${selected_id}" == "" ]]; then
            printError "No organism in DB for : ${nom_valide} >  ${uuid_inpn}"
        else
            local protected_nom_valide="${nom_valide//\'/\'\'}"
            printInfo "Selected organism from ${selected_orga} > ${protected_nom_valide}: ${selected_uuid} => ${selected_id}"

            #if [[ "${id_inpn}" == "" ]] && [[ "${selected_id}" != ${id_inpn} ]]; then
            # Update UUID for selected_id

            local query="UPDATE utilisateurs.bib_organismes SET
                uuid_organisme = '${uuid_inpn}',
                nom_organisme = '${protected_nom_valide}',
                additional_data['isInpnUuid'] = to_jsonb(true)
                WHERE id_organisme='${selected_id}'"
            export PGPASSWORD="${db_pass}"; \
                psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -AXqtc "${query}"
            #fi

            if [[ "${id_cenpaca}" != "" ]] && [[ "${selected_id}" != ${id_cenpaca} ]]; then
                printInfo "\tMerge: CEN-PACA ${id_cenpaca} => ${selected_id}"
                # Merge id_cenpaca to selected_id
                executeMergeOrganismSql "${selected_id}" "${id_cenpaca}"
            fi
            if [[ "${id_cbnmed}" != "" ]] && [[ "${selected_id}" != ${id_cbnmed} ]]; then
                printInfo "\tMerge: CBNMED ${id_cbnmed} => ${selected_id}"
                # Merge id_cbnmed to selected_id
                executeMergeOrganismSql "${selected_id}" "${id_cbnmed}"
            fi
            if [[ "${id_cbna}" != "" ]] && [[ "${selected_id}" != ${id_cbna} ]]; then
                printInfo "\tMerge: CBNA ${id_cbna} => ${selected_id}"
                # Merge id_cbna to selected_id
                executeMergeOrganismSql "${selected_id}" "${id_cbna}"
            fi
        fi

        if ! [[ -n ${verbose-} ]]; then
            (( tasks_done += 1 ))
            displayProgressBar $tasks_count $tasks_done "merging"
        fi
    done < <(stdbuf -oL csvtool -t TAB drop 1 "${organisms_csv_path}")
    echo
}

function getIdByUuid() {
    if [[ $# -lt 2 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    id=""
    local readonly orga="${1}"
    local readonly uuid="${2}"
    if [[ "${uuid}" != "" ]]; then
        local readonly query="SELECT id_organisme FROM utilisateurs.bib_organismes WHERE uuid_organisme='${uuid}'"
        id=`export PGPASSWORD="${db_pass}"; psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -AXqtc "${query}"`

        if [[ "${id}" == "" ]]; then
            printMsg "\tUUID ${orga} not found in DB for ${uuid}"
        fi
    fi
}

function executeMergeOrganismSql() {
    if [[ $# -lt 2 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi

    local readonly new_id_organism="${1}"
    local readonly old_ids_organisms="${2}"

    printMsg "Replacing ${old_ids_organisms} by ${new_id_organism} ..."

    if [[ -n ${new_id_organism-} ]] && [[ -n ${old_ids_organisms-} ]] ; then
        oldIFS="${IFS}"
        export IFS=","
        for old_id_organism in ${old_ids_organisms}; do
            export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" ${psql_verbosity} \
                -v "newIdOrganism=${new_id_organism}" \
                -v "oldIdOrganism=${old_id_organism}" \
                -f "${sql_dir}/01_merge_organism.sql"
        done
        IFS="${oldIFS}"
    else
        printError "Empty id: new_id_organism=${new_id_organism} ; old_id_organism=${old_ids_organisms}"
    fi
}

main "${@}"
