#!/bin/bash
# Encoding : UTF-8
# French administratives areas import script for GeoNature


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
     -i | --id: numeric id of french region to import as SINP area. Ex.: 93 for "PACA region (South of France)"
     -o | --remove-outside_areas: remove areas outside of SINP area if set to "true". Do nothing if "false". Default: "true".
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
            "--id") set -- "${@}" "-i" ;;
            "--remove-outside_areas") set -- "${@}" "-o" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:i:o:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "i") readonly opt_sinp_area_id="${OPTARG}" ;;
            "o") readonly opt_area_remove_outside_areas="${OPTARG}" ;;
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
    redirectOutput "${area_log_imports}"
    checkSuperuser

    # Check commands exist on system
    local readonly commands=("wget" "p7zip" "shp2pgsql" "psql")
    checkBinary "${commands[@]}"

    # Override "area_sinp_region_id" value with command line option value if not empty
    area_sinp_region_id=${opt_sinp_area_id:-$area_sinp_region_id}
    # Override "area_remove_outside_areas" value with command line options value if not empty
    area_remove_outside_areas=${opt_area_remove_outside_areas:-$area_remove_outside_areas}

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "French administrative areas import script started at: ${fmt_time_start}"

    downloadFrenchAdminAreas
    createFrenchAdminRegionAreasSqlFile
    loadSinpArea
    removeAreasOutsideSinpArea

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function download() {
	local readonly url=$1
	local readonly file=$2
	wget --no-check-certificate --progress=dot $url -O $file 2>&1 | grep --line-buffered -E -o "100%|[1-9]0%|^[^%]+$" | uniq
	printVerbose "Download $2 : ${Gre}DONE${RCol}"
}

function downloadFrenchAdminAreas() {
    printMsg "Downloading French admininstrative areas..."
    if ! [[ -d "${raw_shared_dir}/${ign_ae_first_dir}/" ]]; then
        if ! [[ -f "$area_raw_file_path" ]]; then
            download $ign_ae_url $area_raw_file_path
        fi

        printVerbose "Uncompress archive file..."
        cd ${raw_shared_dir}/
        p7zip -d ${area_raw_file_path}
    else
        printVerbose "Archive of french administrative areas was already downloaded !"
    fi
}

function createFrenchAdminRegionAreasSqlFile() {
    printMsg "Create SQL file of french administrative areas..."
    if ! [[ -f "${area_sql_file_path}" ]]; then
        cd ${ign_ae_shape_path}
        echo "\echo '----------------------------------------------------------------------------'" > "${area_sql_file_path}";
        echo "\echo 'Import french administrative regions areas in temporary table ${area_table_name}'" >> "${area_sql_file_path}";
        shp2pgsql -c -D -s 2154 -I "${area_shape_name}" "${area_table_name}" >> "${area_sql_file_path}";
    else
        printVerbose "SQL file of french administrative areas already exists: ${Gre}${area_sql_file_path}"
    fi
}

function loadSinpArea() {
    printMsg "Loading SINP area in database '${area_table_name}'..."

    if [[ "${area_load_sinp_area}" = true ]]; then
        sudo -n -u "${pg_admin_name}" -s \
            psql -d "${db_name}" \
                -v areasTmpTable="${area_table_name}" \
                -v areaSubdividedTableName="${area_subdivided_table_name}" \
                -f "${sql_dir}/001_initialize.sql"

        export PGPASSWORD="$db_pass"; \
            psql -h $db_host -U $db_user -d $db_name \
                -f "${area_sql_file_path}"

        export PGPASSWORD="$db_pass"; \
            psql -h $db_host -U $db_user -d $db_name \
                -v areaSubdividedTableName="${area_subdivided_table_name}" \
                -v areasTmpTable="${area_table_name}" \
                -v sinpRegId="${area_sinp_region_id}" \
                -f "${sql_dir}/002_subdivide_sinp_area.sql"

        removePreviousSinpArea

        export PGPASSWORD="$db_pass"; \
            psql -h $db_host -U $db_user -d $db_name \
                -v areasTmpTable="${area_table_name}" \
                -v sinpRegId="${area_sinp_region_id}" \
                -f "${sql_dir}/004_add_sinp_area.sql"
    else
        local msg="SQL file of french administrative areas was NOT loaded in database"
        printVerbose "${Blink}${Mag}INFO: ${RCol}${Gra}${msg}"
    fi
}

function removePreviousSinpArea() {
    printMsg "Removing previous SINP area..."

    if [[ "${area_remove_previous_sinp}" = true ]]; then
        sudo -n -u "${pg_admin_name}" -s \
            psql -d "${db_name}" \
                -f "${sql_dir}/003_remove_sinp_area.sql"
    else
        local msg="Previous SINP area was NOT removed from database"
        printVerbose "${Blink}${Mag}INFO: ${RCol}${Gra}${msg}"
    fi
}

function removeAreasOutsideSinpArea() {
    printMsg "Removing areas outside SINP area..."

    if [[ "${area_remove_outside_areas}" = true ]]; then
        sudo -n -u "${pg_admin_name}" -s \
            psql -d "${db_name}" \
                -v areasTmpTable="${area_table_name}" \
                -v sinpRegId="${area_sinp_region_id}" \
                -v areaSubdividedTableName="${area_subdivided_table_name}" \
                -f "${sql_dir}/005_remove_outside_areas.sql"
    else
        local msg="Areas are't intersecting with SINP area were NOT removed from database"
        printVerbose "${Blink}${Mag}INFO: ${RCol}${Gra}${msg}"
    fi
}

main "${@}"
