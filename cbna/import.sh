#!/bin/bash
# Encoding : UTF-8
# Import in GeoNature Database the CBNA Flore Data

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
commands=("psql", "pg_restore")
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
rm -f "${log_file}"
touch "${log_file}"
sudo chmod 777 "${log_file}"

#+----------------------------------------------------------------------------------------------------------+
# Redirect output
# Send stdout and stderr in Terminal and log file (remove color characters)
exec 4<&1 5<&2 1>&2>&>(tee -a >(sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' > "${log_file}"))

#+----------------------------------------------------------------------------------------------------------+
# Start script
echo -e "${Whi}CBNA import script started at : `date -d @${TIME_START} "+%Y-%m-%d %H:%M:%S"`${RCol}"

#+----------------------------------------------------------------------------------------------------------+
# Create french region SQL file
echo -e "${Yel}}Create SQL file of french administrative areas${RCol}"
${root_dir}/area/import.sh

#+----------------------------------------------------------------------------------------------------------+
# Run SQL scripts in order
cd $CUR_DIR/

echo -e "${Yel}Réinitialisation de toute la base${RCol}"
export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name -f "${sql_dir}/000_initialize.sql"

echo -e "${Yel}Chargement des régions françaises${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -f "${area_sql_file_path}"

echo -e "${Yel}Insertion dans GeoNature du territoire SINP${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/002_sinp_zone.sql"

echo -e "${Yel}Suppression des zones géo inutiles${RCol}"
echo -e "${Mag}${Blink}Peut durer jusqu'à 5 heures !${RCol}"
export PGPASSWORD="$db_super_pass"; psql -h $db_host -U $db_super_user -d $db_name -f "${sql_dir}/003_remove_areas.sql"

echo -e "${Yel}Chargement des données brutes du CBNA${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/004_import_cbna_raw.sql"

/usr/bin/pg_restore --exit-on-error --verbose --jobs "${pg_restore_jobs}" \
    --host $db_host --port $db_port --username $db_user --dbname $db_name \
    --schema "cbna_flore_global" --table "releve_flore_global" --no-acl --no-owner "${raw_dir}/releve_flore_global.bak"

export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name -f "${sql_dir}/005_rename_cbna.sql"

echo -e "${Yel}Insertion des métadonnées...${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name --echo-all -f "${sql_dir}/006_insert_meta.sql"

echo -e "${Yel}Désactivation des triggers de la table synthese...${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name --echo-all -f "${sql_dir}/007_disable_triggers.sql"

echo -e "${Yel}Insertion dans GeoNature Synthese...${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name --echo-all -f "${sql_dir}/008_insert_synthese.sql"

echo -e "${Yel}Exécution et réactivation des triggers de la table synthese...${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name --echo-all -f "${sql_dir}/009_enable_triggers.sql"

echo -e "${Yel}Nettoyage de la base...${RCol}"
export PGPASSWORD="$db_pass"; psql -h $db_host -U $db_user -d $db_name --echo-all -f "${sql_dir}/010_clean_database.sql"

#+----------------------------------------------------------------------------------------------------------+
# Show time elapsed
TIME_END=$(date +%s)
TIME_DIFF=$(($TIME_END - $TIME_START));
echo -e "${Whi}Total time elapsed : "`displayTime "$TIME_DIFF"`"${RCol}"
