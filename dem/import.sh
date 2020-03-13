#!/bin/bash
# Encoding : UTF-8
# DEM import script for GeoNature
#
# Documentation about it : http://docs.geonature.fr/admin-manual.html?highlight=mnt#referentiel-geographique

#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -e

#+----------------------------------------------------------------------------------------------------------+
# Define constants
TIME_START=$(date +%s)
CUR_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

#+----------------------------------------------------------------------------------------------------------+
# Load config
setting_file_path=$(realpath ${CUR_DIR}/../shared/settings.ini)
if [ -f "$setting_file_path" ] ; then
	source $setting_file_path
	echo -e "${Gra}Config : ${Gre}OK${RCol}"
else
	echo -e "\e[1;31mPlease configure the script by renaming the file 'shared/settings.sample.ini' to 'shared/settings.ini'.\e[0m"
	exit;
fi

#+----------------------------------------------------------------------------------------------------------+
# Load functions
source ${shared_dir}/functions.ini

#+----------------------------------------------------------------------------------------------------------+
# Check commands use by this script exist
echo -e "${Yel}Check system needed commands exist...${RCol}"
commands=("wget", "p7zip", "raster2pgsql", "psql", "jq")
for cmd in "${commands[@]}"; do
    if [ ! -x $(command -v $cmd) ]; then
        echo -e "${Red}Error: please install '$cmd' command.${RCol}" >&2
        exit 1
    fi
done

#+----------------------------------------------------------------------------------------------------------+
# Create log file
if [ ! -d "${log_dir}" ]; then
    echo -e "${Yel}Create log files directory...${RCol}"
    mkdir -p "${log_dir}"
fi

echo -e "${Yel}Create log file...${RCol}"
rm -f "$log_file"
touch "$log_file"
sudo chmod 777 "$log_file"

#+----------------------------------------------------------------------------------------------------------+
# Redirect output
# Send stdout and stderr in Terminal and log file (remove color characters)
exec 4<&1 5<&2 1>&2>&>(tee -a >(sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' > "${log_file}"))

#+----------------------------------------------------------------------------------------------------------+
# Start script
echo -e "${Whi}DEM import script started at : `date -d @${TIME_START} "+%Y-%m-%d %H:%M:%S"`${RCol}"

#+----------------------------------------------------------------------------------------------------------+
# Download DEM file
if ! [ -d "${raw_dir}/${ign_ba_first_dir}/" ]; then
    raw_dem_file_path="${raw_dir}/bdalti_$ign_ba_version.7z"
    if ! [ -f "$raw_dem_file_path" ]; then
        echo -e "${Yel}Download DEM file...${RCol}"
        wget $ign_ba_url -O $raw_dem_file_path
    fi

    echo -e "${Yel}Unzip archive file...${RCol}"
    cd ${raw_dir}/
    p7zip -d $raw_dem_file_path
else
    echo -e "${Gra}DEM file was already downloaded${RCol}"
fi

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Clean DEM GeoNature tables${RCol}"
export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name \
    -c "TRUNCATE TABLE ref_geo.dem RESTART IDENTITY;"
export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name \
    -c "TRUNCATE TABLE ref_geo.dem_vector RESTART IDENTITY;"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Use french administrative areas import script${RCol}"
${root_dir}/area/import.sh

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Load '.asc' files bounding box infos in a temporary database table${RCol}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Drop 'dem_files_tmp' table if exists (due to previous script error)${RCol}"
query="DROP TABLE IF EXISTS ref_geo.dem_files_tmp";
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -t -c "${query}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Create table 'dem_files_tmp'${RCol}"
query="CREATE TABLE ref_geo.dem_files_tmp ( \
    file character varying(100) PRIMARY KEY, \
    geom public.geometry(Geometry, ${db_srid_local}) \
);"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -c "${query}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Extract *.asc files bounding box and insert inside table 'dem_files_tmp'${RCol}"
jq_query=".cornerCoordinates | \
    [ \
        (.upperLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
        (.upperRight | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
        (.lowerRight | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
        (.lowerLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)), \
        (.upperLeft | (.[0] | tostring) + \" \" + (.[1] | tostring)) \
    ] | join(\", \") "

for file in "${raw_dir}/${ign_ba_asc_files_path}/"*.asc; do
    file_name="${file##*/}"
    bbox="$(gdalinfo -json "${file}" | jq "${jq_query}")"
    geom="ST_GeomFromText('POLYGON((${bbox//\"}))', $db_srid_local)"
    query="INSERT INTO ref_geo.dem_files_tmp (file, geom) VALUES ( '${file_name}', ${geom});"
    export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -c "${query}"
done

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Delete all dem file row in table 'dem_files_tmp' not intersecting territory${RCol}"
query="DELETE FROM ref_geo.dem_files_tmp AS dft \
    USING ${area_table_name} AS area  \
    WHERE public.ST_INTERSECTS(area.geom, dft.geom) = false \
    AND ${dem_area_where_clause};"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -c "${query}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Extract '.asc' file names from 'dem_files_tmp' table${RCol}"
query="SELECT file FROM ref_geo.dem_files_tmp";
intersect_files=$(export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -t -q -X -A -c "${query}")

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}\t Drop useless 'dem_files_tmp' table${RCol}"
query="DROP TABLE IF EXISTS ref_geo.dem_files_tmp";
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -t -c "${query}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Load DEM data into GeoNature database${RCol}"
for file in ${intersect_files}; do
    export PGPASSWORD="$db_pass"; \
        raster2pgsql -s $db_srid_local -c -C -I -M -d -t 5x5 \
            ${raw_dir}/${ign_ba_asc_files_path}/${file} ref_geo.dem | \
        psql -h $db_host -U $db_user -d $db_name
done

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Remove DEM raster entries outside territory area${RCol}"
echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
query="DELETE FROM ref_geo.dem AS dem \
    USING ${area_table_name} AS area  \
    WHERE public.ST_INTERSECTS(area.geom, ST_Envelope(dem.rast)) = false \
    AND ${dem_area_where_clause};"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -c "${query}"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Clean database${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name \
    -c "DROP TABLE ${area_table_name};"

#+----------------------------------------------------------------------------------------------------------+
echo -e "${Yel}Rebuild DEM index${RCol}"
echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name \
    -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;"

#+----------------------------------------------------------------------------------------------------------+
if [ "$dem_vectorise" = true ]; then
    echo -e "${Yel}Vectorisation of DEM raster${RCol}"
    echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
    export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name \
        -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;"

    echo -e "${Yel}Refresh DEM vector spatial index${RCol}"
    echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
    export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name \
        -c "REINDEX INDEX ref_geo.index_dem_vector_geom;"
else
    echo -e "${Gra}DEM was NOT vectorized${RCol}"
fi

#+----------------------------------------------------------------------------------------------------------+
# Show time elapsed
TIME_END=$(date +%s)
TIME_DIFF=$(($TIME_END - $TIME_START));
echo -e "${Whi}Total time elapsed : "`displayTime "$TIME_DIFF"`"${RCol}"
