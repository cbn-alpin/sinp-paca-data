#!/bin/bash
# Encoding : UTF-8
# DEM import script for GeoNature
#
# Documentation about it : http://docs.geonature.fr/admin-manual.html?highlight=mnt#referentiel-geographique

#+----------------------------------------------------------------------------------------------------------+
# Define constants
TIME_START=$(date +%s)
CUR_DIR="$( cd "$(dirname "$0")" ; pwd -P )"

#+----------------------------------------------------------------------------------------------------------+
# Load config
setting_file_path=$(realpath ${CUR_DIR}/../shared/settings.ini)
if [ -f $setting_file_path ] ; then
	source $setting_file_path
	echo -e "${Gra}Config : ${Gre}OK${RCol}"
else
	echo -e "\e[1;31mPlease configure the script by renaming the file 'shared/settings.sample.ini' to 'shared/settings.ini'.\e[0m"
	exit;
fi

#+----------------------------------------------------------------------------------------------------------+
# Test zone
# if ! [ -d "${raw_dir}/ADMIN-EXPRESS-COG_1-0__SHP__FRA_2017-06-19/" ]; then
#     echo "NON PRESENT : ${raw_dir}"
# fi
# exit

#+----------------------------------------------------------------------------------------------------------+
# Load functions
. ${shared_dir}/functions.ini

#+----------------------------------------------------------------------------------------------------------+
# Check commands use by this script exist
echo -e "${Yel}Check system needed commands exist...${RCol}"
commands=("wget", "p7zip", "raster2pgsql")
for cmd in "${commands[@]}"; do
    if [ ! -x $(command -v $cmd) ]; then
        echo -e "${Red}Erreur: veuillez installer la commande '$cmd'.${RCol}" >&2
        exit 1
    fi
done

#+----------------------------------------------------------------------------------------------------------+
# Create log file
cd $CUR_DIR

if [ ! -d "${log_dir}" ]; then
    echo -e "${Yel}Create log files directory...${RCol}"
    mkdir -p "${log_dir}"
fi

echo -e "${Yel}Create file log...${RCol}"
rm -f "$log_file"
touch "$log_file"
sudo chmod 777 "$log_file"

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
fi

#+----------------------------------------------------------------------------------------------------------+
# Clean database
echo -e "${Yel}Clean DEM GeoNature tables${RCol}"
export PGPASSWORD="$db_super_pass";psql -h $db_host -U $db_super_user -d $db_name \
    -c "TRUNCATE TABLE ref_geo.dem;" >> $log_file
export PGPASSWORD="$db_super_pass";psql -h $db_host -U $db_super_user -d $db_name \
    -c "TRUNCATE TABLE ref_geo.dem_vector;" &>> $log_file

#+----------------------------------------------------------------------------------------------------------+
# Import DEM into DB
echo -e "${Yel}Load DEM data into GeoNature database${RCol}"
export PGPASSWORD="$db_pass"; \
    raster2pgsql -s $db_srid_local -c -C -I -M -d -t 5x5 \
        ${raw_dir}/${ign_ba_asc_files_path}/*.asc ref_geo.dem | \
    psql -h $db_host -U $db_user -d $db_name \
    &>> $log_file

#+----------------------------------------------------------------------------------------------------------+
# Rebuild index
echo -e "${Yel}Rebuild DEM index${RCol}"
echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
export PGPASSWORD="$db_super_pass";psql -h $db_host -U $db_super_user -d $db_name \
    -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;" &>> $log_file

#+----------------------------------------------------------------------------------------------------------+
# Remove DEM outside territory
# TODO !

#+----------------------------------------------------------------------------------------------------------+
# Vectorize DEM
if [ "$dem_vectorise" = true ]; then
    printMsg "Vectorisation of DEM raster"
    echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
    export PGPASSWORD="$db_super_pass";psql -h $db_host -U $db_super_user -d $db_name \
        -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" \
    &>> $log_file
    
    printMsg "Refresh DEM vector spatial index"
    echo -e "${Mag}${Blink}This may take a few minutes !${RCol}"
    export PGPASSWORD="$db_super_pass";psql -h $db_host -U $db_super_user -d $db_name \
        -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" \
    &>> $log_file
fi

#+----------------------------------------------------------------------------------------------------------+
# Show time elapsed
TIME_END=$(date +%s)
TIME_DIFF=$(($TIME_END - $TIME_START));
echo -e "${Whi}Total time elapsed : "`displayTime "$TIME_DIFF"`"${RCol}"