#!/bin/bash
# Encoding : UTF-8
# DEM import script for GeoNature
#
# Doc: http://docs.geonature.fr/admin-manual.html?highlight=mnt#referentiel-geographique


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
    redirectOutput "${dem_log_imports}"
    checkSuperuser

    # Check commands exist on system
    local readonly commands=("wget" "p7zip" "raster2pgsql" "psql" "jq" "gdalinfo")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "DEM import script started at: ${fmt_time_start}"

    downloadDem
    importTerritoryArea
    prepareDbBeforeDemImport
    importDemFilesInTmpTable
    deleteDemFilesNotInTerritory
    loadDemFilesMatchingTerritory
    cleanDbAfterDemImport
    vectorizeDem

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadDem() {
    printMsg "Downloading IGN BdAlti ..."

    if ! [[ -d "${raw_shared_dir}/${ign_ba_first_dir}/" ]]; then
        if ! [[ -f "$dem_raw_file_path" ]]; then
            download $ign_ba_url $dem_raw_file_path
        fi

        printVerbose "Uncompress archive file..."
        cd ${raw_shared_dir}/
        p7zip -d ${dem_raw_file_path}
    else
        printVerbose "\tArchive of IGN BdAlti was already downloaded !"
    fi
}

function download() {
	local readonly url=$1
	local readonly file=$2
	wget --no-check-certificate --progress=dot $url -O $file 2>&1 | grep --line-buffered -E -o "100%|[1-9]0%|^[^%]+$" | uniq
	printVerbose "Download $2 : ${Gre}DONE${RCol}"
}

function importTerritoryArea() {
    local verbose_option="$([[ ${verbose} ]] && echo '-v' || echo '')"
    ${root_dir}/area/bin/initialize.sh --remove-outside_areas false --id "${dem_sinp_region_id}" "${verbose_option}"
}

function prepareDbBeforeDemImport() {
    printMsg "Preparing database before DEM import ..."

    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v localSrid="${db_srid_local}" \
            -f "${sql_dir}/001_before_dem_import.sql"
}

function importDemFilesInTmpTable() {
    printMsg "Extracting *.asc files bounding box and inserting inside table 'dem_files_tmp' ..."

    local jq_query=".cornerCoordinates | \
        [ \
            (.upperLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
            (.upperRight | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
            (.lowerRight | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
            (.lowerLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
            (.upperLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)) \
        ] | join(\", \") "

    for file in "${raw_shared_dir}/${ign_ba_asc_files_path}/"*.asc; do
        local file_name="${file##*/}"
        local bbox="$(gdalinfo -json "${file}" | jq "${jq_query}")"
        local geom="ST_GeomFromText('POLYGON((${bbox//\"}))', ${db_srid_local})"

        local query="INSERT INTO ref_geo.dem_files_tmp (file, geom) VALUES ( '${file_name}', ${geom} ) ;"
        export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -c "${query}"
    done
}

function deleteDemFilesNotInTerritory() {
    printMsg "Deleting all dem file row in table 'dem_files_tmp' not intersecting territory ..."

    query="DELETE FROM ref_geo.dem_files_tmp AS dft \
        USING ${area_table_name} AS area  \
        WHERE public.ST_INTERSECTS(area.geom, dft.geom) = false \
        AND insee_reg = '${dem_sinp_region_id}' ;"
    export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -c "${query}"
}

function loadDemFilesMatchingTerritory() {
    printMsg "Loading only asc files matching territory in 'dem' table"

    printVerbose "Extract '.asc' file names from 'dem_files_tmp' table"
    query="SELECT file FROM ref_geo.dem_files_tmp";
    intersect_files=$(export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -t -q -X -A -c "${query}")

    printVerbose "Load DEM data into GeoNature database"
    for file in ${intersect_files}; do
        export PGPASSWORD="${db_pass}"; \
            raster2pgsql -s "${db_srid_local}" -c -C -I -M -d -t 5x5 \
                ${raw_shared_dir}/${ign_ba_asc_files_path}/${file} ref_geo.dem | \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}"
    done
}

function deleteDemNotInTerritory() {
    printMsg "Removing DEM raster entries outside territory area"

    printVerbose "${Mag}${Blink}This may take a few minutes !"
    local query="DELETE FROM ref_geo.dem AS dem \
        USING ${area_table_name} AS area  \
        WHERE public.ST_INTERSECTS(area.geom, ST_Envelope(dem.rast)) = false \
        AND insee_reg = '${dem_sinp_region_id}' ;"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -c "${query}"
}

function cleanDbAfterDemImport() {
    printMsg "Cleaning database after DEM import ..."

    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v areaTable="${area_table_name}" \
            -f "${sql_dir}/002_after_dem_import.sql"
}

function vectorizeDem() {
    if [[ "${dem_vectorise}" = true ]]; then
        printMsg "Vectorizing DEM raster"
        printVerbose "${Mag}${Blink}This may take a few minutes !"
        local query="INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem ;"
        export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -c "${query}"

        printMsg "Refreshing DEM vector spatial index"
        printVerbose "${Mag}${Blink}This may take a few minutes !"
        local query="REINDEX INDEX ref_geo.index_dem_vector_geom ;"
        export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -c "${query}"
    else
        printInfo "\tDEM was NOT vectorized !"
    fi
}

main "${@}"
