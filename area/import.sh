#!/bin/bash
# Encoding : UTF-8
# French administratives areas import script for GeoNature

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
commands=("wget", "p7zip", "shp2pgsql", "psql")
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
echo -e "${Whi}French administrative areas import script started at: `date -d @${TIME_START} "+%Y-%m-%d %H:%M:%S"`${RCol}"

#+----------------------------------------------------------------------------------------------------------+
if ! [ -d "${raw_data_shared_dir}/${ign_ae_first_dir}/" ]; then
    echo -e "${Yel}Downloading French admininstrative areas...${RCol}"
    if ! [ -f "$area_raw_file_path" ]; then
        wget $ign_ae_url -O $area_raw_file_path
    fi

    echo -e "${Yel}Uncompress archive file...${RCol}"
    cd ${raw_data_shared_dir}/
    p7zip -d ${area_raw_file_path}
else
    echo -e "${Gra}Archive of french administrative areas was already downloaded${RCol}"
fi

#+----------------------------------------------------------------------------------------------------------+
if ! [ -f "${area_sql_file_path}" ]; then
    echo -e "${Yel}Create SQL file of french administrative areas...${RCol}"
    cd ${ign_ae_shape_path}
    echo "-- This content will be replaced by data downloaded via import.sh" > "${area_sql_file_path}";
    shp2pgsql -c -D -s 2154 -I "${area_shape_name}" "${area_table_name}" >> "${area_sql_file_path}";
else
    echo -e "${Gra}SQL file of french administrative areas already exists: ${Gre}${area_sql_file_path}${RCol}"
fi

#+----------------------------------------------------------------------------------------------------------+
if [ "${area_load_sql}" = true ]; then
    echo -e "${Yel}Loading french administrative areas in database '${area_table_name}'${RCol}"
    export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name \
        -c "DROP TABLE IF EXISTS ${area_table_name};"
    export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name \
        -f "${area_sql_file_path}"
else
    echo -e "${Gra}SQL file of french administrative areas was NOT loaded in database${RCol}"
fi

#+----------------------------------------------------------------------------------------------------------+
# Show time elapsed
TIME_END=$(date +%s)
TIME_DIFF=$(($TIME_END - $TIME_START));
echo -e "${Whi}Total time elapsed : "`displayTime "$TIME_DIFF"`"${RCol}"
